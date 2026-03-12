#!/bin/bash
# OpenClaw 学员运维巡检脚本
# 用法: ssh 进学员机器后执行，或通过远程 SSH 调用
# 需要 PATH 包含 openclaw

export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

echo "============================================"
echo "🔍 OpenClaw 运维巡检 - $(date '+%Y-%m-%d %H:%M:%S')"
echo "📍 $(hostname) | $(whoami)"
echo "============================================"
echo ""

# ========== 1. 版本检查与更新 ==========
echo "【1】版本检查"
echo "--------------------------------------------"
# 获取完整状态（后续多处复用）
STATUS_OUTPUT=$(openclaw status 2>&1)
CURRENT=$(echo "$STATUS_OUTPUT" | grep -oE "app [0-9]{4}\.[0-9]+\.[0-9]+" | head -1 | sed 's/app //')
[ -z "$CURRENT" ] && CURRENT=$(openclaw version 2>/dev/null | grep -oE "[0-9]{4}\.[0-9]+\.[0-9]+" | head -1)
echo "当前版本: ${CURRENT:-未知}"

# 检查是否有更新
if echo "$STATUS_OUTPUT" | grep -q "Update.*available"; then
    UPDATE_LINE=$(echo "$STATUS_OUTPUT" | grep -oE "npm (update|latest) [0-9.]+")
    echo "⚠️  有更新可用: $UPDATE_LINE"
    echo "💡 更新命令: openclaw update"
else
    echo "✅ 已是最新版本"
fi
echo ""

# ========== 2. Cron 检查 ==========
echo "【2】Cron 定时任务检查"
echo "--------------------------------------------"
CRON_OUTPUT=$(openclaw cron list --json 2>/dev/null)
if [ $? -ne 0 ] || [ -z "$CRON_OUTPUT" ] || [ "$CRON_OUTPUT" = "[]" ]; then
    echo "📋 无定时任务"
else
    CRON_COUNT=$(echo "$CRON_OUTPUT" | python3 -c "import sys,json; data=json.load(sys.stdin); jobs=data.get('jobs',data) if isinstance(data,dict) else data; print(len(jobs))" 2>/dev/null || echo "?")
    echo "📋 共 $CRON_COUNT 个定时任务:"
    echo ""
    echo "$CRON_OUTPUT" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    jobs = data.get('jobs', data) if isinstance(data, dict) else data
    for j in jobs:
        name = j.get('name', j.get('id', '?')[:12])
        enabled = '✅' if j.get('enabled', True) else '❌'
        sched = j.get('schedule', {})
        kind = sched.get('kind', '?')
        if kind == 'every':
            ms = sched.get('everyMs', 0)
            if ms >= 3600000:
                interval = f'{ms/3600000:.1f}h'
            elif ms >= 60000:
                interval = f'{ms/60000:.0f}m'
            else:
                interval = f'{ms/1000:.0f}s'
            sched_str = f'每 {interval}'
        elif kind == 'cron':
            sched_str = f'cron: {sched.get(\"expr\", \"?\")}'
        elif kind == 'at':
            sched_str = f'一次性: {sched.get(\"at\", \"?\")[:19]}'
        else:
            sched_str = str(sched)
        
        payload = j.get('payload', {})
        p_kind = payload.get('kind', '?')
        target = j.get('sessionTarget', '?')
        
        # 合理性检查
        warnings = []
        if kind == 'every' and ms < 60000:
            warnings.append('🔴 间隔<1分钟！会疯狂创建session导致CPU爆炸')
        elif kind == 'every' and ms < 300000:
            warnings.append('⚠️ 间隔<5分钟，token消耗大+session堆积风险')
        if kind == 'cron':
            # 检查cron表达式是否过于频繁
            expr = sched.get('expr', '')
            parts_e = expr.split()
            if len(parts_e) >= 1 and parts_e[0].startswith('*/') and parts_e[0] != '*/5':
                try:
                    mins = int(parts_e[0].replace('*/', ''))
                    if mins < 5:
                        warnings.append(f'🔴 每{mins}分钟触发！session会疯狂堆积')
                except: pass
            if len(parts_e) >= 2 and parts_e[1].startswith('*/'):
                pass  # 每N小时是合理的
        if target == 'main' and p_kind != 'systemEvent':
            warnings.append('⚠️ main会话应用systemEvent')
        if target == 'isolated' and p_kind != 'agentTurn':
            warnings.append('⚠️ isolated应用agentTurn')
        
        warn_str = ' | '.join(warnings) if warnings else ''
        print(f'  {enabled} {name:<20} | {sched_str:<15} | {p_kind}/{target} {warn_str}')
except Exception as e:
    print(f'  解析失败: {e}')
" 2>/dev/null
fi
echo ""

# ========== 3. Session 检查 ==========
echo "【3】Session 会话检查"
echo "--------------------------------------------"
SESSION_FILE=$(find ~/.openclaw -name "sessions.json" -type f 2>/dev/null | head -1)
if [ -n "$SESSION_FILE" ]; then
    FILE_SIZE=$(ls -lh "$SESSION_FILE" 2>/dev/null | awk '{print $5}')
    echo "📁 sessions.json 大小: $FILE_SIZE"
fi

# 用 openclaw status 提取 session 信息
echo ""
echo "$STATUS_OUTPUT" | python3 -c "
import sys
lines = sys.stdin.read()
# 提取 Sessions 行
in_sessions = False
session_count = 0
large_sessions = []
for line in lines.split('\n'):
    if '│ Sessions' in line or '│ sessions' in line.lower():
        # 提取总数
        import re
        m = re.search(r'(\d+)\s*(active|个)', line)
        if m:
            session_count = int(m.group(1))
    # 提取 session 表格行
    if '│ agent:' in line:
        parts = [p.strip() for p in line.split('│') if p.strip()]
        if len(parts) >= 5:
            key = parts[0][:50]
            age = parts[2] if len(parts) > 2 else '?'
            tokens = parts[4] if len(parts) > 4 else (parts[3] if len(parts) > 3 else '?')
            # 检查 token 占比
            import re
            pct_match = re.search(r'\((\d+)%\)', tokens)
            pct = int(pct_match.group(1)) if pct_match else 0
            status = ''
            if pct >= 80:
                status = '🔴 接近上限'
            elif pct >= 60:
                status = '⚠️ 较大'
            large_sessions.append((key, age, tokens, pct, status))

print(f'📊 总会话数: {session_count}')
if session_count > 100:
    print(f'⚠️  会话数较多({session_count})，建议清理旧会话')
elif session_count > 500:
    print(f'🔴 会话数过多({session_count})，强烈建议清理')
else:
    print(f'✅ 会话数正常')

print()
if large_sessions:
    print('会话详情（按 token 占比排序）:')
    for key, age, tokens, pct, status in sorted(large_sessions, key=lambda x: -x[3])[:10]:
        print(f'  {pct:>3}% | {age:<10} | {key} {status}')
    
    high = [s for s in large_sessions if s[3] >= 60]
    if high:
        print(f'\n⚠️  {len(high)} 个会话 token 占比 ≥60%，可能需要 /compact')
" 2>/dev/null

echo ""

# ========== 3.5 Session 文件深度检查 ==========
echo "【3.5】Session 存储深度检查"
echo "--------------------------------------------"
# 检查所有 sessions.json 文件
TOTAL_SESSION_SIZE=0
for sf in $(find ~/.openclaw -name "sessions.json" -type f 2>/dev/null); do
    SIZE_BYTES=$(stat -f%z "$sf" 2>/dev/null || stat --printf="%s" "$sf" 2>/dev/null || echo "0")
    SIZE_MB=$((SIZE_BYTES / 1048576))
    SIZE_HUMAN=$(ls -lh "$sf" 2>/dev/null | awk '{print $5}')
    LINE_COUNT=$(wc -l < "$sf" 2>/dev/null || echo "0")
    AGENT=$(echo "$sf" | sed 's|.*agents/||;s|/sessions.*||')
    
    if [ "$SIZE_MB" -ge 100 ]; then
        echo "🔴 $AGENT: $SIZE_HUMAN ($LINE_COUNT 行) — 严重膨胀！会导致 CPU 飙高"
    elif [ "$SIZE_MB" -ge 50 ]; then
        echo "⚠️  $AGENT: $SIZE_HUMAN ($LINE_COUNT 行) — 偏大，建议清理"
    elif [ "$SIZE_MB" -ge 10 ]; then
        echo "⚠️  $AGENT: $SIZE_HUMAN ($LINE_COUNT 行) — 较大"
    else
        echo "✅ $AGENT: $SIZE_HUMAN ($LINE_COUNT 行)"
    fi
done

# 检查 CPU 占用
echo ""
GATEWAY_CPU=$(ps aux | grep "openclaw-gateway\|openclaw.*gateway" | grep -v grep | awk '{print $3}' | head -1)
if [ -n "$GATEWAY_CPU" ]; then
    CPU_INT=${GATEWAY_CPU%.*}
    if [ "${CPU_INT:-0}" -ge 80 ]; then
        echo "🔴 Gateway CPU: ${GATEWAY_CPU}% — 异常！检查 session 膨胀或 cron 风暴"
    elif [ "${CPU_INT:-0}" -ge 30 ]; then
        echo "⚠️  Gateway CPU: ${GATEWAY_CPU}% — 偏高"
    else
        echo "✅ Gateway CPU: ${GATEWAY_CPU}%"
    fi
fi
echo ""

# ========== 4. 总览 ==========
echo "【4】Gateway 状态总览"
echo "--------------------------------------------"
openclaw gateway status 2>/dev/null | head -8 || echo "⚠️ 无法获取 Gateway 状态"
echo ""

# 渠道状态
echo "【5】渠道状态"
echo "--------------------------------------------"
openclaw channels status --probe 2>/dev/null || echo "$STATUS_OUTPUT" | grep -E "│.*(ON|OFF|Discord|Telegram|WhatsApp|Slack|Signal)" | head -10
echo ""

# ========== 6. 工作区文件检查 ==========
echo "【6】工作区文件检查"
echo "--------------------------------------------"
WORKSPACE=$(openclaw config get agents.defaults.workspace 2>/dev/null | tr -d '"' || echo "$HOME/.openclaw/workspace")
[ ! -d "$WORKSPACE" ] && WORKSPACE="$HOME/.openclaw/workspace"
if [ -d "$WORKSPACE" ]; then
    for f in SOUL.md AGENTS.md MEMORY.md IDENTITY.md USER.md TOOLS.md HEARTBEAT.md; do
        if [ -f "$WORKSPACE/$f" ]; then
            SIZE=$(wc -c < "$WORKSPACE/$f" | tr -d ' ')
            LINES=$(wc -l < "$WORKSPACE/$f" | tr -d ' ')
            if [ "$SIZE" -gt 20000 ]; then
                echo "⚠️  $f: ${LINES}行 ${SIZE}字节 — 偏大，可能有冗余内容"
            else
                echo "✅ $f: ${LINES}行 ${SIZE}字节"
            fi
        else
            echo "📭 $f: 不存在"
        fi
    done
    
    # 检查各文件之间是否有内容重复（简单检查）
    if [ -f "$WORKSPACE/SOUL.md" ] && [ -f "$WORKSPACE/IDENTITY.md" ]; then
        OVERLAP=$(comm -12 <(grep -oE '\w{6,}' "$WORKSPACE/SOUL.md" | sort -u) <(grep -oE '\w{6,}' "$WORKSPACE/IDENTITY.md" | sort -u) 2>/dev/null | wc -l | tr -d ' ')
        if [ "${OVERLAP:-0}" -gt 20 ]; then
            echo "⚠️  SOUL.md 和 IDENTITY.md 有较多重复词（$OVERLAP 个），建议精简"
        fi
    fi
else
    echo "⚠️  工作区目录不存在: $WORKSPACE"
fi
echo ""

echo "============================================"
echo "✅ 巡检完成"
echo "============================================"
