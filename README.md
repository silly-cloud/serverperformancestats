# serverperformancestats
Server performance stats analyzer. Shows CPU usage, memory (total/used/free),  disk usage, and top 5 processes by CPU and memory. One-liner execution on any Linux.

# server-stats.sh

Quick Linux server performance analyzer. Get CPU, memory, disk usage, and top processes in seconds.

## Features

- **CPU Usage** - Overall percentage, core count, load average
- **Memory** - Total, used, free with percentage
- **Disk** - Total, used, free with percentage (root filesystem)
- **Top 5 CPU Processes** - PIDs and command names
- **Top 5 Memory Processes** - PIDs and command names

## Installation

```bash
chmod +x server-stats.sh
```

## Usage

```bash
./server-stats.sh
```

## Output

```
=== CPU ===
Usage: 25%
Cores: 8
Load:  0.45, 0.52, 0.48

=== MEMORY ===
Total: 15Gi
Used: 8Gi (53%)
Free: 7Gi

=== DISK ===
Total: 100G
Used: 45G (45%)
Free: 55G

=== TOP 5 CPU ===
12.5% PID:1234 apache2
8.3% PID:5678 mysql
5.1% PID:9012 python
3.2% PID:3456 node
2.1% PID:7890 java

=== TOP 5 MEMORY ===
8.5% PID:5678 mysql
6.2% PID:3456 node
4.1% PID:7890 java
3.5% PID:1234 apache2
2.8% PID:9012 python
```

## Requirements

Linux with standard utilities: `bash`, `grep`, `awk`, `free`, `df`, `ps`, `uptime`, `nproc`

## License

MIT
