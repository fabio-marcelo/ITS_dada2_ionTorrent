# download de db unite
wget -c https://files.plutof.ut.ee/public/orig/98/AE/98AE96C6593FC9C52D1C46B96C2D9064291F4DBA625EF189FEC1CCAFCF4A1691.gz

tar xzf 98AE96C6593FC9C52D1C46B96C2D9064291F4DBA625EF189FEC1CCAFCF4A1691.gz

cd sh_qiime_release_04.02.2020/developer/



# download da versao sh_qiime_release_s_29.11.2022.tgz
wget -c https://files.plutof.ut.ee/public/orig/98/AE/671C4D441E50DCD30691B84EED22065D77BAD3D18AF1905675633979BF323754.tgz \
    -O sh_qiime_release_s_29.11.2022.tgz


awk '/^>/ {print($0)}; /^[^>]/ {print(toupper($0))}' sh_refs_qiime_ver8_99_04.02.2020_dev.fasta \
| tr -d ' ' > sh_refs_qiime_ver8_99_04.02.2020_dev_uppercase.fasta