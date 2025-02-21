#!/bin/bash

# Mặc định số replicas và NODE_ID
DEFAULT_REPLICAS=1
DEFAULT_NODE_ID=""

# Hiển thị menu
while true; do
    clear
    echo "🚀 Quản lý Nexus Containers"
    echo "=============================="
    echo "1️⃣ Chạy Nexus với số replicas tùy chọn"
    echo "2️⃣ Xóa toàn bộ Nexus containers"
    echo "3️⃣ Xem logs của tất cả Nexus containers"
    echo "4️⃣ Thoát"
    echo "=============================="
    read -p "🔹 Chọn một tùy chọn (1-4): " CHOICE

    case "$CHOICE" in
        1)
            # Nhập số replicas
            read -p "Nhập số lượng replicas (mặc định: $DEFAULT_REPLICAS): " REPLICAS
            REPLICAS=${REPLICAS:-$DEFAULT_REPLICAS}

            # Nhập NODE_ID
            read -p "Nhập NODE_ID (bỏ trống nếu không có): " NODE_ID
            NODE_ID=${NODE_ID:-$DEFAULT_NODE_ID}

            # Xóa docker-compose.yml cũ nếu có
            rm -f docker-compose.yml

            # Tạo file docker-compose.yml
            echo "version: '3.8'" >> docker-compose.yml
            echo "services:" >> docker-compose.yml
            for i in $(seq 1 $REPLICAS); do
                cat <<EOF >> docker-compose.yml
  nexus$i:
    image: inanitynoupcase/nexus_2:1.2.0
    environment:
      - NODE_ID=$NODE_ID
    ports:
      - "$((8080 + i)):80"
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"

EOF
            done

            # Khởi động docker-compose
            docker-compose up -d
            echo "✅ Đã khởi động $REPLICAS node Nexus với tên nexus1 → nexus$REPLICAS."
            read -p "Nhấn Enter để tiếp tục..."
            ;;

        2)
            # Xóa toàn bộ containers Nexus
            echo "🛑 Đang xóa toàn bộ containers Nexus..."
            docker ps -a --format "{{.Names}}" | grep "^nexus[0-9]*$" | xargs -r docker rm -f
            echo "✅ Tất cả Nexus containers đã bị xóa!"
            read -p "Nhấn Enter để tiếp tục..."
            ;;

        3)
            # Xem logs từng container Nexus
            echo "📜 Đang hiển thị logs của tất cả Nexus containers..."
            for CONTAINER in $(docker ps --format "{{.Names}}" | grep "^nexus[0-9]*$"); do
                echo "🔹 [${CONTAINER}] Logs:"
                docker logs --tail 10 -f "$CONTAINER" &
                sleep 0.5  # Tránh spam logs quá nhanh
            done
            wait
            read -p "Nhấn Enter để tiếp tục..."
            ;;

        4)
            echo "👋 Thoát chương trình. Hẹn gặp lại!"
            exit 0
            ;;

        *)
            echo "❌ Lựa chọn không hợp lệ! Vui lòng chọn lại."
            sleep 2
            ;;
    esac
done
