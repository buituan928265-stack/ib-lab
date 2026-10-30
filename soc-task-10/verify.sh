#!/bin/bash
cd /root/soc-lab && docker compose exec -T analyst soc check 10 >/dev/null 2>&1
