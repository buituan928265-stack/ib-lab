#!/bin/bash
cd /root/ib-lab/soc-lab && docker compose exec -T analyst soc check 12 >/dev/null 2>&1
