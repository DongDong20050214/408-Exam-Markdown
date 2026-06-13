---
name: TCP状态机
type: 知识点定义
subject: 计算机网络
chapter: 传输层
---

# TCP状态机

## 定义
TCP 状态机描述 TCP 连接在不同状态间的转移，反映连接的生命周期。

## 核心概念
- LISTEN：服务器等待连接
- SYN_SENT：客户端发送 SYN
- SYN_RCVD：服务器收到 SYN
- ESTABLISHED：连接建立，数据传输
- FIN_WAIT_1/2：主动关闭方，等待 FIN
- CLOSE_WAIT：被动关闭方，等待关闭
- TIME_WAIT：最后等待，2×MSL 后关闭
- CLOSED：连接关闭

## 算法流程/关键公式
1. 客户端：CLOSED → SYN_SENT → ESTABLISHED → FIN_WAIT_1 → FIN_WAIT_2 → TIME_WAIT → CLOSED
2. 服务器：LISTEN → SYN_RCVD → ESTABLISHED → CLOSE_WAIT → LAST_ACK → CLOSED

## 易混淆点
| FIN_WAIT_1 | FIN_WAIT_2 | 区别 |
|------------|-----------|------|
| 发送 FIN 后 | 收到 ACK 后 | 顺序不同 |

## 关联知识点
- [TCP连接管理](TCP连接管理.md)
- [TCP协议](TCP协议.md)

## 历年真题
- TCP 状态转移
- 各状态含义