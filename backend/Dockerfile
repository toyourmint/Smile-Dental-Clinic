# 1️⃣ เลือก image แม่ (Node.js)
FROM node:20

# 2️⃣ ตั้งโฟลเดอร์ทำงานใน container
WORKDIR /app

# 3️⃣ คัดลอกไฟล์ dependency
COPY package*.json ./

# 4️⃣ ติดตั้ง dependency
RUN npm install

# 5️⃣ คัดลอก source code ทั้งหมด
COPY . .

# 6️⃣ เปิด port (บอกว่าแอปรันพอร์ตไหน)
EXPOSE 3000

# 7️⃣ คำสั่งตอน container start
CMD ["npm", "start"]