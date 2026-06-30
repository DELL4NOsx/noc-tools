#!/bin/bash

DNS1="170.83.172.10"
DNS2="170.83.172.11"

DOMAINS=(

    # INTERNOS
    "semfronteirasnet.com.br"
    "opasf.semfronteiras.net.br"
    "zabbixmw.semfronteiras.net.br"
    "sistemamw.semfronteiras.net.br"
    "grafanamw.semfronteiras.net.br"

    # EXTERNO PROVA
    "google.com"

)

echo "======================================"
echo " DETECTOR CACHE NEGATIVO DNSSEC (EDE)"
echo "======================================"
date
echo ""

for domain in "${DOMAINS[@]}"; do

    echo ">>> $domain"

    OUT1=$(dig $domain @$DNS1 +dnssec)
    OUT2=$(dig $domain @$DNS2 +dnssec)

    STATUS1=$(echo "$OUT1" | grep "status" | awk '{print $6}')
    STATUS2=$(echo "$OUT2" | grep "status" | awk '{print $6}')

    EDE1=$(echo "$OUT1" | grep "EDE: 29")
    EDE2=$(echo "$OUT2" | grep "EDE: 29")

    echo "DNS1 ($DNS1): $STATUS1"
    echo "DNS2 ($DNS2): $STATUS2"

    if [[ -n "$EDE1" ]]; then
        echo "DNS1: 🔴 CACHE NEGATIVO DNSSEC DETECTADO"
    fi

    if [[ -n "$EDE2" ]]; then
        echo "DNS2: 🔴 CACHE NEGATIVO DNSSEC DETECTADO"
    fi

    if [[ -z "$EDE1" && -z "$EDE2" && "$STATUS1" == "NOERROR" ]]; then
        echo "STATUS: ✅ OK"
    fi

    echo ""
done

echo "======================================"
echo "FIM"
