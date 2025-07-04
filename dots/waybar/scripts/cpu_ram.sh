#!/bin/bash

# Get CPU usage (simplified approach)
cpu_usage=$(grep 'cpu ' /proc/stat | awk '{usage=($2+$4)*100/($2+$3+$4+$5)} END {print int(usage)}')

# Get RAM usage in GB
ram_used=$(free -g | awk '/^Mem:/{printf "%.1f", $3}')

# Output the combined string
printf "CPU %s%% RAM %sG\n" "$cpu_usage" "$ram_used" 