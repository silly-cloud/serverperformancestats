#!/bin/bash

echo "========== Server Stats =========="
echo "Date: $(date)"
echo "Uptime: $(uptime -p)"
echo "CPU Load: $(top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}')%"
echo "Memory Usage: $(free -h | awk '/^Mem:/ {print $3  "/" $2}')"
echo "Disk Usage: $(df -h / | awk 'NR==2 {print $3 " used of " $2}')"

echo "====== CPU Usage Details ======"\
grep "^cpu " /proc/stat | awk '{print "Usage: " int(100*($2+$4+$7)/($2+$3+$4+$5+$6+$7)) "%"}'
echo "Cores: $(nproc)"
echo "Load: $(uptime | awk -F'load average:' '{print $2}')"

echo -e "\n======= Memory Usage Details ======="
free -h | grep Mem | awk '{print "Total: " $2 ",\nUsed: " $3 ",\nFree: " $4}'

echo -e "\n======= Disk Usage Details ======="
df -h / | tail -1 | awk '{print "Total: " $2 ",\nUsed: " $3 ",\nAvailable: " $4 ",\nUsage: " $5}'

echo -e "\n======= Top 5 Memory-Consuming Processes ======="
ps aux --sort=-%cpu | head -6 | tail -5 | awk '{printf "%s%% PID:%s %s\n", $3, $2, $11}'

echo -e "\n======= Top 5 CPU-Consuming Processes ======="
ps aux --sort=-%mem | head -6 | tail -5 | awk '{printf "%s%% PID:%s %s\n", $4, $2, $11}'

echo "=================================="
