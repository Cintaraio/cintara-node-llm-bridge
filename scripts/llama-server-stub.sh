#!/bin/bash
echo "Starting LLM placeholder server on port 8000..."
while true; do
    {
        echo -e "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nConnection: close\r\n"
        echo -e "\r\n{\"status\":\"ready\",\"model\":\"tinyllama\",\"context_length\":1024}"
    } | nc -l -p 8000 -q 1 2>/dev/null || sleep 2
done