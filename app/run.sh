#!/bin/bash

# Tutarlı değişken adlandırma küçük harf ve alt çizgi ile
config_dir="/DATA/AppData/casamod"
mod_dir="${config_dir}/mod"
mod_store_dir="${config_dir}/mod_store"
icon_dir="${config_dir}/icon"

www_dir="/var/lib/casaos/www"
index_html="${www_dir}/index.html"
index_html_bak="${index_html}.bak"

casaos_framework="gin"

host_exec() {
  nsenter -m -u -i -n -p -t 1 sh -c "$1"
}

start() {
  echo "Başlatılıyor..."

  # v0.4.10+ gin'den echo'ya geçiş
  casaos_ver=$(host_exec "casaos -v | tr -d 'v'")
  if [[ $(printf "%s\n" "$casaos_ver" "0.4.9" | sort -V | tail -n1) == "$casaos_ver" ]]; then
    casaos_framework="echo"
    echo "CasaOS v$casaos_ver"
  fi

  # mod_store'u kopyala
  if [[ ! -d "$mod_store_dir" ]]; then
    echo "${mod_store_dir} dizini oluşturuluyor"
    mkdir -p "$mod_store_dir"
    cp -r /app/mod/* "$mod_store_dir"
    echo -e "Bu klasörü silin ve yeni sürüm konteyner başlatıldığında yeniden oluşturulacak.\n\nDelete this folder and it will be recreated when the new version of the container is started." >>"${mod_store_dir}/Recreated_Store.txt"
  fi

  # İşleme eşleme dizini
  for dir in "$mod_dir" "$icon_dir"; do
    #Dizin oluşturuluyor
    if [[ ! -d "$dir" ]]; then
      echo "${dir} dizini oluşturuluyor"
      mkdir -p "$dir"
      # README oluşturuluyor
      if [[ "$dir" == "$icon_dir" ]]; then
        echo -e "Bu klasör http(s)://casaos/icon/* ile erişilebilir, örneğin app1.png yerleştirebilir ve uygulama simge ayarlarında icon/app1.png doldurabilirsiniz.\n\nThis folder can be accessed by http(s)://casaos/icon/*, e.g. you can place app1.png and fill in icon/app1.png in the app icon settings." >>"${icon_dir}/README.txt"
      fi
    fi
    # Symlink oluşturuluyor
    symlink_dir="${www_dir}/${dir##*/}"
    if [[ ! -d "$symlink_dir" ]]; then
      echo "${dir}'den ${symlink_dir}'e symlink oluşturuluyor"
      ln -s "$dir" "$symlink_dir"
    fi
  done

  # config_dir'de www_dir için symlink oluştur
  # www_link="${config_dir}/www"
  # if [[ ! -d "$www_link" ]]; then
  #   echo "${www_dir}'den ${www_link}'e symlink oluşturuluyor"
  #   ln -s "$www_dir" "$www_link"
  # fi

  # index.html'yi yedekle
  if [[ ! -f "$index_html_bak" ]]; then
    cp "$index_html" "$index_html_bak"
    echo "index.html yedeklendi"
  else
    cp "$index_html_bak" "$index_html"
  fi

  # Modlar için etiketler oluştur
  js_tags=""
  css_tags=""
  for mod_path in "$mod_dir"/*; do
    mod_js_path="${mod_path}/mod.js"
    mod_css_path="${mod_path}/mod.css"
    if [[ -f "$mod_js_path" ]]; then
      echo "${mod_js_path} okunuyor"
      js_tags+="<script type=\"text/javascript\" src=\"mod/${mod_path##*/}/mod.js\"></script>\n"
    fi
    if [[ -f "$mod_css_path" ]]; then
      echo "${mod_css_path} okunuyor"
      css_tags+="<link href=\"/mod/${mod_path##*/}/mod.css\" rel=\"stylesheet\">\n"
    fi
  done
  if [[ -z "$js_tags" ]]; then
    js_tags="\n<!-- CasaMOD yüklendi, ancak js bulunamadı -->\n"
  else
    js_tags="\n<!-- CasaMOD js -->\n${js_tags}"
  fi
  #echo "$js_tags"
  if [[ -z "$css_tags" ]]; then
    css_tags="\n<!-- CasaMOD yüklendi, ancak css bulunamadı -->\n"
  else
    css_tags="\n<!-- CasaMOD css -->\n${css_tags}"
  fi
  #echo "$css_tags"

  # index.html'yi değiştir
  sed -i "s|<title>|${css_tags}<title>|" "$index_html"
  sed -i "s|<\/body>|${js_tags}<\/body>|" "$index_html"
  echo "index.html değiştirildi"

  # Ağ geçidini yeniden başlat
  if [[ $casaos_framework == "echo" ]]; then
    host_exec "systemctl restart casaos-gateway.service"
    echo "casaos-gateway.service yeniden başlatıldı"
  fi

  echo "Çalışmaya devam ediliyor..."
  while true; do
    sleep 1
  done
}

stop() {
  echo "Durduruluyor..."
  if [[ -f "$index_html_bak" ]]; then
    cp "$index_html_bak" "$index_html"
    rm "$index_html_bak"
    echo "index.html geri yüklendi"
    if [[ $casaos_framework == "echo" ]]; then
      host_exec "systemctl restart casaos-gateway.service"
      echo "casaos-gateway.service yeniden başlatıldı"
    fi
  else
    echo "Yedek dosya bulunamadı, index.html geri yüklenemiyor"
  fi
  exit 0
}

trap 'stop' SIGINT SIGTERM

case "$1" in
start)
  start
  ;;
stop)
  stop
  ;;
*)
  echo "Geçersiz komut. Desteklenen komutlar: start, stop"
  exit 1
  ;;
esac
