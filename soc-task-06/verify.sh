#!/bin/bash
cd /root/ib-lab/soc-lab && docker compose exec -T analyst soc check 06 >/dev/null 2>&1
