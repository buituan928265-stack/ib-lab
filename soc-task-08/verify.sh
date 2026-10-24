#!/bin/bash
cd /root/ib-lab/soc-lab && docker compose exec -T analyst soc check 08 >/dev/null 2>&1
