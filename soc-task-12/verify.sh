#!/bin/bash
cd /root/soc-lab && docker compose exec -T analyst soc check 12 >/dev/null 2>&1
