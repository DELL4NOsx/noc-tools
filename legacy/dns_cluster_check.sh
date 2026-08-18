#!/bin/bash

DNS1="192.0.2.53"
DNS2="198.51.100.53"

DOMAINS=(

    # INTERNOS
    "dns.internal.example"
    "monitoring.internal.example"
    "service.internal.example"
    "system.internal.example"
    "dashboard.internal.example"

    # EXTERNOS
    "example.com"
    "example.net"
    "example.org"

)

echo "======================================"
echo " DNS CLUSTER CHECK - NOC (PRO)"
echo "======================================"
date
echo ""

for domain in "${DOMAINS[@]}"; do

    R1=$(dig +short $domain @$DNS1 +time=1 +tries=1 | head -n1)
    R2=$(dig +short $domain @$DNS2 +time=1 +tries=1 | head -n1)

    T1=$(dig $domain @$DNS1 +stats +time=1 +tries=1 | grep "Query time" | awk '{print $4}')
    T2=$(dig $domain @$DNS2 +stats +time=1 +tries=1 | grep "Query time" | awk '{print $4}')

    [[ -z "$R1" ]] && R1="FAIL"
    [[ -z "$R2" ]] && R2="FAIL"

    printf "%-40s\n" ">>> $domain"
    echo "DNS1: $R1 (${T1}ms)"
    echo "DNS2: $R2 (${T2}ms)"

    # CLASSIFICAÇÃO INTELIGENTE
    if [[ "$R1" == "FAIL" && "$R2" == "FAIL" ]]; then
        echo "STATUS: 🔴 CRÍTICO (ambos falharam)"
    elif [[ "$R1" == "FAIL" && "$R2" != "FAIL" ]]; then
        echo "STATUS: 🔴 CRÍTICO (DNS1 falhando)"
    elif [[ "$R1" != "FAIL" && "$R2" == "FAIL" ]]; then
        echo "STATUS: 🔴 CRÍTICO (DNS2 falhando)"
    elif [[ "$R1" != "$R2" ]]; then
        echo "STATUS: ⚠ INFO (respostas válidas porém diferentes)"
    else
        echo "STATUS: ✅ OK"
    fi

    echo ""
done

echo ">>> Teste IP interno de monitoramento (203.0.113.10)"
ping -c 2 203.0.113.10 >/dev/null && echo "Monitoramento interno: OK" || echo "Monitoramento interno: FAIL"

echo ""
echo "======================================"
echo "FIM"
