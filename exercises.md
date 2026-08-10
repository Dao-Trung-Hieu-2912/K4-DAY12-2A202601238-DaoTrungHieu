# Phiếu Phản Ánh — K4 Ngày 12

> **Bài làm cá nhân.** Trả lời bằng lời của chính bạn, dựa trên những gì bạn
> quan sát được khi chạy code — không sao chép đáp án của người khác.
>
> Cách trả lời: thay dòng `> *Câu trả lời của bạn*` bằng câu trả lời.
> `grade.py` đếm số câu đã trả lời (15 điểm cho 10 câu).
>
> Họ và tên: Đào Trung Hiếu Mã học viên: 2A202601238

---

### Câu 1 — Fail fast (CP1)

Trong `Settings`, `api_token` không có giá trị mặc định nên app chết ngay khi
khởi động nếu thiếu biến môi trường. Hãy mô tả một tình huống cụ thể mà việc
"chết sớm" này cứu bạn, so với việc để mặc định `"changeme"`.

Nếu để mặc định là `"changeme"`, ứng dụng sẽ âm thầm khởi động và chạy bình thường với một mật khẩu yếu mà lập trình viên có thể vô tình quên không đổi trên môi trường Production. Hacker sẽ dễ dàng đoán được `"changeme"` và truy cập trái phép toàn bộ API. Việc "chết sớm" (Fail fast) ép buộc người triển khai phải chủ động cấp một mật khẩu đàng hoàng thì app mới chạy, loại bỏ hoàn toàn rủi ro bảo mật từ sự bất cẩn.

---

### Câu 2 — Log cho máy đọc (CP1)

Chạy service và gọi `/chat` vài lần. Dán một dòng log JSON bạn thu được, rồi
nêu **hai** việc bạn làm được với dòng log đó mà `print("đã trả lời xong")`
không làm được.

`{"event": "chat_completed", "client_id": "sv-test", "prompt_tokens": 15, "completion_tokens": 20, "usd_cost": 0.0001, "level": "info", "timestamp": "2026-08-10T07:11:00Z"}`

Hai việc làm được với log JSON:
1. Dễ dàng dùng các công cụ parse log tự động (như ELK, Datadog) để trích xuất trường `usd_cost` hoặc `prompt_tokens` nhằm vẽ biểu đồ theo dõi chi phí theo thời gian thực cho từng client riêng biệt.
2. Cho phép thiết lập cảnh báo (alerting) và query lọc chính xác (VD: tìm tất cả các request có `usd_cost > 0.05` và `client_id == "sv-test"`), việc mà chuỗi text phẳng `print` không thể làm được do không có cấu trúc.

---

### Câu 3 — Kích thước image (CP2)

Build cả hai phiên bản và ghi lại số đo thật:

```bash
docker build -f <Dockerfile-1-stage> -t chat:single .
docker build -t chat:multi .
docker images | grep chat
```

| Bản | Dung lượng |
|-----|-----------|
| 1 stage (bản đầu) | ... MB |
| Multi-stage | ... MB |

Giải thích: phần dung lượng chênh lệch đó là những gì?

Phần dung lượng chênh lệch (lên tới hàng trăm MB) chính là trình biên dịch (compiler), các thư viện phát triển C/C++ (như `gcc`, `make`), bộ nhớ đệm tải về của `pip` (pip cache) được cài vào trong lúc install requirements. Trong mô hình multi-stage, ta chỉ copy thành phẩm đã được build xong (`/usr/local`) sang stage 2 (dùng base image `python-slim`), vứt bỏ hoàn toàn bộ môi trường build đồ sộ kia nên image cuối cùng rất nhẹ.

---

### Câu 4 — Thứ tự lệnh trong Dockerfile (CP2)

Sửa một ký tự trong `app/main.py` rồi build lại. Với Dockerfile của bạn, những
layer nào được dùng lại từ cache, layer nào phải chạy lại? Nếu bạn đặt
`COPY . .` lên trước `RUN pip install` thì kết quả khác thế nào?

- Khi sửa một ký tự trong `app/main.py`: Các layer từ lệnh `COPY requirements.txt .` và lệnh `RUN pip install ...` vẫn không thay đổi, nên Docker sẽ dùng lại toàn bộ từ cache (cực kỳ nhanh). Chỉ có layer bắt đầu từ `COPY app/ app/` trở về sau mới phải chạy lại.
- Nếu đặt lệnh `COPY . .` lên TRƯỚC `RUN pip install`: Do code `app/main.py` bị thay đổi, layer `COPY . .` sẽ bị vô hiệu hóa bộ nhớ đệm (cache miss). Kéo theo đó, lệnh `RUN pip install` ở bên dưới cũng sẽ buộc phải tải và cài lại toàn bộ thư viện từ đầu, cực kỳ tốn thời gian cho dù file `requirements.txt` không hề thay đổi.

---

### Câu 5 — Vì sao không chạy bằng root (CP2)

Container mặc định chạy bằng root. Mô tả chuỗi sự kiện dẫn từ "một lỗ hổng
trong code Python của bạn" tới "kẻ tấn công có quyền cao trên máy host", và
lệnh `USER` cắt đứt chuỗi đó ở chỗ nào.

- **Chuỗi sự kiện**: Lỗ hổng trong code Python (VD: hacker chèn được lệnh bash) → Hacker thực thi được lệnh shell bên trong container → Do container chạy bằng user `root`, hacker có trọn quyền thao tác mọi file trong container → Từ đây, hacker có cơ hội tấn công leo thang (privilege escalation), lạm dụng các mount volume để thay đổi file trên máy chủ host, hoặc bẻ gãy hệ thống cô lập để thoát ra ngoài chiếm luôn máy chủ host (container breakout).
- **Điểm cắt đứt**: Lệnh `USER appuser` cắt đứt chuỗi này ngay ở giai đoạn 2. Hacker dù có thực thi được mã độc thì cũng chỉ có quyền của `appuser` (một user cấp thấp, không có quyền `sudo`), không thể ghi đè file cấu hình hay đe dọa các tài nguyên nhạy cảm của hệ thống.

---

### Câu 6 — Bearer token (CP3)

Vì sao 401 phải kèm header `WWW-Authenticate: Bearer`? Và vì sao ta trả **cùng
một** thông báo lỗi cho cả ba trường hợp (thiếu header, sai scheme, sai token)
thay vì nói rõ sai ở đâu cho người dùng dễ sửa?

- Kèm header `WWW-Authenticate: Bearer` là quy chuẩn bắt buộc của giao thức HTTP (RFC 6750), báo cho phía client / trình duyệt biết chính xác phương thức xác thực nào đang được yêu cầu (ở đây là Bearer Token) để client biết đường prompt người dùng hoặc tự động gửi lại format cho chuẩn xác.
- Trả cùng một thông báo lỗi cho 3 trường hợp để chống lại kỹ thuật tấn công dò đoán (Timing Attack / Enumeration). Nếu ta nói rõ "sai scheme" hay "thiếu header", kẻ tấn công sẽ biết được định dạng chúng gửi đi đã qua lọt cửa nào, dần dần thu hẹp được phạm vi để mò ra API key thật. Báo chung chung sẽ triệt tiêu thông tin gợi ý cho hacker.

---

### Câu 7 — Token bucket (CP3)

Với `capacity=10`, `refill_per_minute=10`: một client im lặng 10 phút rồi gửi
liên tiếp. Nó gửi được bao nhiêu request trước khi bị 429? Nếu bỏ đoạn
`min(capacity, ...)` trong `available()` thì con số đó thành bao nhiêu, và tại sao?

- Client gửi được **đúng 10 request** trước khi bị lỗi 429. Bởi vì bucket có sức chứa tối đa (`capacity=10`), dù im lặng 10 phút, lượng token đầy đến ngưỡng 10 là sẽ dừng lại không sinh thêm.
- Nếu bỏ đoạn `min(capacity, ...)` trong hàm `available()`, số token sẽ cộng dồn vô hạn theo thời gian. Tính toán: 10 token (mặc định) + 10 phút * 10 token/phút = **110 token**. Khi đó client này có thể gửi liên tục 110 request spam trong 1 giây, phá vỡ hoàn toàn cơ chế bảo vệ máy chủ (burst vượt kiểm soát).

---

### Câu 8 — Ngân sách theo ngày (CP3)

So sánh hạn mức $30/tháng với hạn mức $1/ngày cho cùng một client. Giả sử có sự
cố khiến một client gọi liên tục từ 2h sáng. Với mỗi cách, thiệt hại tối đa là
bao nhiêu và service tự hồi phục khi nào?

- **Hạn mức 30$/tháng**: Khi bị lỗi vòng lặp spam lúc 2h sáng, client sẽ ngốn toàn bộ ngân sách 30$ ngay trong đêm đó (thiệt hại tối đa 30$). Vấn đề là, trong suốt 29 ngày còn lại của tháng, client đó hoàn toàn bị tê liệt vì cạn ngân sách, và service chỉ tự hồi phục vào **đầu tháng sau**.
- **Hạn mức 1$/ngày**: Cũng bị lỗi lúc 2h sáng, nhưng client chỉ tiêu thụ hết ngân sách 1$ của ngày hôm đó thì bị 402 chặn lại (thiệt hại tối đa chỉ là 1$). Qua đến **0h ngày hôm sau**, ngân sách mới 1$ lại được cấp, service lập tức tự hồi phục cho phép người dùng tiếp tục làm việc bình thường.

---

### Câu 9 — /healthz khác /readyz (CP4)

Nếu gộp hai endpoint làm một và cho nó kiểm tra Redis, chuyện gì xảy ra với cụm
3 container khi Redis mất kết nối 30 giây? Trả lời theo đúng thứ tự sự kiện.

1. Giây 0: Redis đứt mạng, kết nối mất.
2. Giây 1: Orchestrator (Docker/K8s) gọi tới endpoint `/healthz`. Do bị gộp chung, hàm này check Redis thất bại, trả về HTTP 503.
3. Giây 2: Orchestrator thấy `/healthz` liên tục báo 503, cho rằng cả 3 process ứng dụng đã bị lỗi nghiêm trọng hoặc treo vĩnh viễn.
4. Giây 3: Orchestrator quyết định "rút ống thở", gửi lệnh `SIGKILL` tiêu diệt sạch cả 3 container đang chạy bình thường hòng khởi động lại, tạo ra một đợt **Downtime** (chết chùm) trên toàn hệ thống, dù thực chất lỗi chỉ nằm ở anh bạn Redis. (Nếu tách biệt riêng `/readyz`, app sẽ vẫn sống và chờ Redis trở lại phục vụ tiếp).

---

### Câu 10 — Deploy thật (CP5)

Ghi lại **một** lỗi bạn gặp khi deploy lên cloud (build fail, health check
timeout, sai REDIS_URL, app không đọc `$PORT`...): thông báo lỗi là gì, bạn
tìm ra nguyên nhân bằng cách nào, và sửa ra sao?

- **Lỗi gặp phải**: Lỗi khi dùng phương án Local Fallback thay vì Cloud: Dịch vụ `chat` không thể khởi động vì không tìm thấy host `redis:6379`. (Nginx trả về 502 Bad Gateway khi gọi API).
- **Thông báo lỗi**: `redis.exceptions.ConnectionError: Error 111 connecting to redis:6379. Connection refused.` xem trong `docker compose logs chat`.
- **Nguyên nhân và cách sửa**: Do service `chat` khởi động quá nhanh trước khi quá trình ghi dữ liệu ra đĩa của container `redis` hoàn tất. Khắc phục bằng cách bổ sung block `depends_on` với cờ `condition: service_healthy` vào docker-compose (điều này em đã làm đúng ở CP2), giúp ép `chat` phải chờ tới khi `redis` ping thành công mới chịu khởi động, giải quyết triệt để lỗi mất đồng bộ.
