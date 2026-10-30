#!/bin/bash
. /opt/astra/tasks/lib.sh
L=/var/log/portal/access.log
if [ "$1" = "--reset" ] || [ ! -s $L ]; then
  rm -rf /root/report; mkdir -p /var/log/portal
  # адрес:число запросов
  IPS="10.0.5.17:83 192.168.1.40:61 10.0.5.22:47 172.16.0.9:31 10.0.7.3:12 192.168.1.15:9 10.0.5.200:5 172.16.0.44:2"
  PAGES="/ /docs/500 /login /api/v1/orders /api/v1/report /static/app.js /docs/404 /upload"
  CODES="200 200 200 200 200 304 200 404 500 200 302 200 503 200 404 200 502 200"
  SIZES="512 404 1834 500 2311 503 0 7840"
  awk -v ips="$IPS" -v pages="$PAGES" -v codes="$CODES" -v sizes="$SIZES" 'BEGIN{
    n=split(ips,I," "); np=split(pages,P," "); nc=split(codes,C," "); ns=split(sizes,S," ");
    for(i=1;i<=n;i++){split(I[i],a,":"); for(j=0;j<a[2];j++) L[k++]=a[1]}
    # перемешиваем детерминированно
    for(i=k-1;i>0;i--){j=(i*7919+13)%(i+1); t=L[i]; L[i]=L[j]; L[j]=t}
    for(i=0;i<k;i++){ s=i*13; m=int(s/60); 
      printf "%s - - [30/Oct/2026:%02d:%02d:%02d +0300] \"GET %s HTTP/1.1\" %s %s \"-\" \"Mozilla/5.0 (X11; Linux x86_64)\"\n",
        L[i], 9+int(m/60), m%60, s%60, P[(i*5)%np+1], C[(i*11)%nc+1], S[(i*3)%ns+1] }
  }' > $L
  chmod 644 $L
  md5sum $L | cut -d' ' -f1 > /var/lib/.astra-04-log.md5
fi
true
