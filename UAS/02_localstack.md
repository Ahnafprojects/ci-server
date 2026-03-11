## ☁️ Modul Pengantar: Konsep Cloud dan LocalStack

### 1. Pengantar Teknologi Cloud (Perkenalan)

Bagian ini bertujuan memberikan pemahaman mendasar mengenai *Cloud Computing* dan model layanannya.

#### A. Definisi *Cloud Computing*

Materi ini memberikan fondasi konseptual tentang apa itu *Cloud Computing* dan mengapa teknologi ini menjadi standar industri.

##### 1. Definisi Inti

* **Definisi:** *Cloud Computing* adalah model penyediaan layanan komputasi (*server*, *storage*, *database*, *networking*, *analytics*, dan *software*) melalui internet (**cloud**) berdasarkan permintaan (*on-demand*) dengan skema bayar-sesuai-penggunaan (*pay-as-you-go*).

##### 2. Keunggulan Utama

Teknologi *Cloud Computing* memberikan beberapa keunggulan fundamental dibandingkan infrastruktur tradisional:

* **Skalabilitas:** Kemampuan untuk **meningkatkan atau menurunkan** kapasitas *resource* komputasi (CPU, RAM, *storage*) secara virtual seketika, memungkinkan sistem menangani pertumbuhan data atau pengguna yang cepat.
* **Elastisitas:** Kemampuan sistem untuk secara **otomatis menyesuaikan *resource*** agar sesuai dengan beban kerja yang berfluktuasi. Contoh: Menambahkan *server* baru secara otomatis saat lalu lintas tinggi, dan menghapusnya saat lalu lintas rendah.
* **Efisiensi Biaya:** Menggunakan model bayar-sesuai-penggunaan (*pay-as-you-go*). Pengguna hanya membayar untuk *resource* yang benar-benar dikonsumsi, menghilangkan kebutuhan akan investasi awal yang besar pada infrastruktur fisik (**Capital Expenditure/CapEx** berubah menjadi **Operational Expenditure/OpEx**).
#### B. Model Layanan *Cloud*

Menjelaskan tiga model utama yang menentukan tingkat abstraksi dan tanggung jawab pengguna:

| Model | Singkatan | Fokus Utama | Contoh |
| :--- | :--- | :--- | :--- |
| **Infrastructure as a Service** | IaaS | Menyediakan *resource* komputasi dasar (VM, *Storage*, Jaringan). | Amazon EC2, Azure Virtual Machines |
| **Platform as a Service** | PaaS | Menyediakan lingkungan pengembangan dan *deployment* lengkap (OS, *Runtime*, Middleware). | AWS Elastic Beanstalk, Azure App Service |
| **Software as a Service** | SaaS | Menyediakan aplikasi perangkat lunak yang siap digunakan. | Gmail, Office 365, Salesforce |

---

### 2. Penyedia Layanan *Cloud* Utama (Provider) 🌐

Bayangkan *Cloud Computing* sebagai pasar raksasa yang menyediakan semua jenis kebutuhan komputasi. Ada tiga perusahaan besar yang mendominasi dan menguasai sebagian besar pasar ini—mereka adalah **Provider** atau **Penyedia Layanan *Cloud* Utama**.

Layanan dari *provider-provider* inilah yang akan kita coba tiru (emulasi) secara lokal menggunakan LocalStack.


#### A. Amazon Web Services (AWS) 🥇

AWS dimiliki oleh Amazon (perusahaan *e-commerce* raksasa). AWS adalah pemimpin pasar dan bisa dibilang yang paling penting untuk dipelajari.

* **Penyedia Terbesar dan Pelopor (*First Mover*):** AWS adalah perusahaan pertama yang meluncurkan layanan *cloud* berskala besar pada tahun 2006. Karena memulai lebih dulu, mereka memiliki pangsa pasar terbesar di dunia.
* **Layanan Paling Lengkap:** AWS menawarkan ribuan layanan, mulai dari yang paling sederhana hingga yang paling kompleks.
* **Contoh Layanan Kunci:**
    * **Amazon EC2 (Elastic Compute Cloud):** Ini adalah layanan mesin virtual (VM) dasar. Bayangkan Anda menyewa sebuah komputer virtual di pusat data AWS.
    * **Amazon S3 (Simple Storage Service):** Layanan *storage* objek tak terbatas (seperti *hard drive* di *cloud*) untuk menyimpan *file* dan data dalam jumlah besar. Ini adalah *service* yang paling sering kita emulasikan.
    * **AWS Lambda:** Layanan **Serverless Computing**. Anda menjalankan kode Anda tanpa perlu mengurus server sama sekali.

---

#### B. Microsoft Azure 🥈

Azure adalah layanan *cloud* yang ditawarkan oleh Microsoft. Azure sangat kuat di kalangan perusahaan (*enterprise*) dan organisasi yang sudah menggunakan produk Microsoft lainnya (seperti Windows Server, Office 365, dan .NET).

* **Integrasi dengan Ekosistem Microsoft:** Azure menawarkan integrasi yang sangat mulus dengan *software* Microsoft yang sudah ada. Jika sebuah perusahaan sudah menggunakan Windows dan Microsoft SQL Server, mereka sering memilih Azure karena *tool*-nya terasa familiar.
* **Kekuatan di *Hybrid Cloud*:** Azure unggul dalam membantu perusahaan menghubungkan pusat data lokal mereka dengan *cloud* publik, menciptakan **Hybrid Cloud** yang mulus.

---

#### C. Google Cloud Platform (GCP) 🥉

GCP adalah layanan *cloud* yang ditawarkan oleh Google. Meskipun pangsa pasarnya lebih kecil dari AWS dan Azure, GCP dikenal karena keunggulan teknologinya yang berasal dari infrastruktur internal Google.

* **Keunggulan *Big Data* dan *Machine Learning*:** GCP dikenal unggul di bidang-bidang yang membutuhkan kekuatan komputasi besar, seperti pemrosesan data raksasa dan kecerdasan buatan, karena mereka menggunakan teknologi yang sama dengan mesin pencari Google.
* **Kubernetes (GKE):** Google adalah penemu dari teknologi *container orchestration* yang disebut **Kubernetes**. Oleh karena itu, *service* Kubernetes mereka, yaitu **Google Kubernetes Engine (GKE)**, dianggap sebagai salah satu yang terbaik di industri.



### 3 Cloud Computing dan DevOps
#### A. Definisi DevOps (Development & Operations)

* **DevOps (Development & Operations):** **Bukan sekadar *tool* atau peran**; melainkan sebuah **filosofi budaya** yang bertujuan menyatukan *people* (orang), *process* (proses), dan *products* (teknologi) untuk memungkinkan **pengiriman nilai secara berkelanjutan** (*continuous delivery*) kepada pengguna akhir.
* **Tujuan Utama:** Mempersingkat *System Development Life Cycle* (SDLC) dan menyediakan *fitur* atau perbaikan dengan kualitas tinggi, kecepatan, dan keandalan yang tinggi.

#### B. Pilar Utama DevOps

Filosofi ini diwujudkan melalui empat pilar praktik utama, yang semuanya sangat didukung oleh kapabilitas *cloud*:

| Pilar Utama DevOps | Penjelasan Detil | Keterkaitan dengan Cloud |
| :--- | :--- | :--- |
| **Otomasi (Automation)** | Memanfaatkan *software* dan *tool* untuk menghilangkan tugas-tugas manual yang berulang dan rentan *error*, seperti *provisioning* infrastruktur dan *testing*. | *Cloud* menyediakan API untuk mengotomasi *resource* melalui **IaC (Infrastructure as Code)**. |
| **Pengiriman Berkelanjutan (CI/CD)** | Memastikan kode baru selalu diintegrasikan (CI) dan di-*deploy* (CD) ke produksi dengan aman dan cepat, seringkali beberapa kali dalam sehari. | *Cloud* menyediakan *resource* instan dan *ephemeral* (berumur pendek) yang diperlukan untuk menjalankan *pipeline* *testing* dan *staging* yang cepat. |
| **Kolaborasi (Collaboration)** | Menghilangkan sekat antara tim *Development* (pembuat kode) dan *Operations* (pengelola infrastruktur) sehingga mereka berbagi tujuan dan tanggung jawab yang sama. | *Cloud* menyediakan *platform* dan *tool* *monitoring* terintegrasi yang dapat diakses bersama, memfasilitasi *troubleshooting* bersama. |
| ***Feedback Loop*** **yang Cepat** | Mekanisme di mana data kinerja, *logging*, dan *error* dari lingkungan produksi dapat dilihat oleh tim *development* secara *real-time*. | *Cloud* menyediakan layanan *monitoring* dan *logging* bawaan (*managed services*) yang memberikan umpan balik instan tentang kesehatan aplikasi. |

#### C. Mengapa Cloud Diperlukan oleh DevOps? 🤔

*Cloud Computing* menyediakan landasan teknis agar prinsip-prinsip DevOps dapat berjalan secara efektif.

| Prinsip DevOps | Kontribusi Cloud Computing | Fungsi Utama |
| :--- | :--- | :--- |
| **A. Otomasi Infrastruktur** | **Infrastructure as Code (IaC)** | *Cloud* memungkinkan infrastruktur (VM, *database*, *storage*) ditulis sebagai kode (misalnya, dengan Terraform, CloudFormation). Ini menggantikan *setup* manual yang lambat dan rawan *error* di *data center* tradisional. |
| **B. Pengiriman Berkelanjutan (CI/CD)** | **Elastisitas dan *On-Demand*** | DevOps membutuhkan lingkungan *testing* dan *staging* yang dapat dibuat dan dihancurkan dengan cepat (*ephemeral*). *Cloud* menyediakan *resource* instan dan *on-demand* untuk menjalankan *pipeline* CI/CD. |
| **C. Skalabilitas dan Kecepatan** | **Skala Global dan *Resource* Instan** | *Cloud* menyediakan *resource* tak terbatas. DevOps dapat merespons beban kerja yang berubah-ubah (*auto-scaling*) dan *deployment* ke berbagai *region* global, sesuatu yang mustahil dilakukan oleh *data center* lokal biasa. |
| **D. Monitoring dan *Feedback*** | **Layanan Terkelola (*Managed Services*)** | *Cloud providers* menawarkan layanan *monitoring* dan *logging* bawaan (misalnya, AWS CloudWatch). Ini menyediakan *feedback loop* real-time yang cepat, fundamental bagi DevOps untuk mengidentifikasi dan memperbaiki masalah. |

---

#### D. Hubungan Simbiosis (Sintesis) 🤝

Hubungan antara *Cloud Computing* dan DevOps adalah hubungan simbiosis; keduanya saling membutuhkan untuk mencapai efisiensi tertinggi dalam pengiriman perangkat lunak. Tanpa *Cloud Computing*, praktik DevOps menjadi sangat terhambat dan mahal, dan sebaliknya, *Cloud* tanpa filosofi DevOps tidak dapat memberikan nilai maksimalnya.

* **DevOps Tanpa Cloud:** Praktik DevOps seperti otomasi dan *Continuous Integration/Continuous Delivery* (CI/CD) **masih mungkin** dilakukan di infrastruktur lokal (*on-premise*), tetapi kemampuannya **terbatas**. Keterbatasan utama berasal dari **lambatnya penyediaan *resource* fisik** dan **biaya Capital Expenditure (CapEx)** yang tinggi. Otomasi seringkali terhenti di level aplikasi karena *setup* dan penghancuran infrastruktur (VM, jaringan) membutuhkan waktu dan campur tangan manual.

* **Cloud Tanpa DevOps:** Jika sebuah tim hanya memindahkan *server* dan *database* mereka ke *Cloud* (seperti AWS atau Azure) tanpa mengadopsi otomasi dan CI/CD, maka *Cloud* tersebut hanyalah **infrastruktur *hosting* yang mahal**. Tim tidak memanfaatkan fitur-fitur penting *Cloud* seperti **skalabilitas otomatis** (*auto-scaling*), **IaC**, dan **penyediaan *resource* instan**. Mereka pada dasarnya hanya menggunakan *Cloud* sebagai *data center* biasa, sehingga tidak mencapai **efisiensi biaya** dan **kecepatan** yang dijanjikan.

* **Kesimpulan Hubungan:**
    * **Cloud Computing** adalah ***enabler* teknis** yang menyediakan *resource* tak terbatas, fleksibel, dan *on-demand*.
    * **DevOps** adalah **filosofi dan proses** yang memaksimalkan penggunaan *resource* tersebut melalui otomasi, kolaborasi, dan *feedback loop* yang cepat, memastikan pengiriman *software* yang cepat, andal, dan efisien.


### 4. Mengapa Kita Membutuhkan LocalStack? 🤔

Meskipun *Cloud Computing* menawarkan banyak keunggulan, melakukan pengembangan dan pengujian berulang kali langsung pada lingkungan *cloud* publik (AWS asli) dapat menimbulkan masalah, terutama dalam fase awal pengembangan. Kita membutuhkan LocalStack sebagai lingkungan emulasi lokal untuk mengatasi tantangan tersebut.

#### A. Tantangan Pengembangan *Cloud* Asli

Melakukan *testing* langsung ke *endpoint* publik AWS menghadapi tiga kendala utama yang merusak kecepatan dan efisiensi tim DevOps:

##### 1. Biaya (*Cost*) yang Tidak Terduga 💸

* **Detail:** Layanan *cloud* beroperasi dengan model **bayar-sesuai-penggunaan (*pay-as-you-go*)**. Meskipun ini efisien untuk produksi, pengembang yang melakukan pengujian berulang (*unit testing*, *integration testing*, *debugging*) dapat secara tidak sengaja meninggalkan *resource* mahal yang berjalan (misalnya, *database* RDS, VM EC2, atau fungsi Lambda yang sering dipanggil).
* **Dampaknya:** Hal ini dapat menyebabkan **biaya yang tak terduga (*unexpected bills*)** yang tinggi di akhir bulan, menjadikannya tidak ideal untuk lingkungan edukasi atau *sandbox* di mana pengujian sering gagal dan harus diulang.

##### 2. Keterlambatan (*Latency*) dan Ketidakefisienan ⏱️

* **Detail:** Setiap kali *developer* menguji aplikasi atau memanggil *service* (misalnya, membuat *bucket* S3, mengirim pesan SQS), permintaan tersebut harus melakukan perjalanan melalui internet ke *Region* AWS terdekat dan kembali (*round-trip*).
* **Dampaknya:** Keterlambatan (*latency*) ini, meskipun hanya sepersekian detik, terakumulasi menjadi waktu tunggu yang lama dalam siklus *Development-Test-Debug* yang berulang. Kecepatan *feedback loop* DevOps menjadi melambat.

##### 3. Ketergantungan Jaringan (*Network Dependency*) 📵

* **Detail:** Akses ke *Cloud* publik **mutlak** membutuhkan koneksi internet yang stabil dan tersedia.
* **Dampaknya:** Pengembangan dan pengujian tidak dapat dilakukan **secara *offline***. Jika koneksi internet terputus atau tidak stabil, seluruh tim pengembang berhenti bekerja karena mereka tidak dapat memanggil *endpoint* AWS yang diperlukan.



#### B. Peran dan Manfaat LocalStack

LocalStack adalah *framework* yang bertindak sebagai "AWS palsu" di komputer lokal Anda, memungkinkan Anda mengembangkan dan menguji aplikasi *cloud* dengan cepat dan aman tanpa biaya.

| Manfaat | Fungsi LocalStack | Relevansi Detail untuk DevOps |
| :--- | :--- | :--- |
| **1. Pengujian *Offline*** 💻 | **Mengemulasi API AWS secara lokal di komputer Host Anda.** | LocalStack memastikan *developer* **tidak bergantung pada koneksi internet** yang stabil. Pengembangan dan *debugging* dapat dilakukan kapan saja, di mana saja, menjamin kontinuitas kerja, yang sangat mendukung prinsip **Elastisitas Waktu** dalam DevOps. |
| **2. Pengurangan Biaya** 💰 | **Semua *resource* (S3 *bucket*, *SQS queue*, *Lambda function*, dll.) dibuat tanpa biaya sama sekali.** | Karena semua layanan berjalan di **Docker container** menggunakan *resource* laptop Anda, Anda **tidak dikenakan biaya** oleh AWS. Ini menghemat biaya AWS yang signifikan, menjadikannya solusi **wajib** untuk lingkungan edukasi, pelatihan, dan *sandbox* di mana *resource* sering dibuat dan dihapus untuk pengujian. |
| **3. Kecepatan Umpan Balik** ⚡ | **Waktu tunggu (*latency*) sangat rendah karena komunikasi hanya terjadi antara *Host* dan *container* Docker.** | Saat Anda menjalankan perintah AWS CLI, permintaannya hanya berjalan dari *Host* Anda ke *LocalStack container* (via `localhost:4566`) dan kembali. *Latency* ini **jauh lebih cepat** daripada *round-trip* ke *Region* AWS publik, secara drastis mempercepat siklus *Development-Test-Debug* dan *feedback loop* DevOps. |
| **4. Isolasi Lingkungan** 🛡️ | **Lingkungan lokal yang terisolasi, memastikan tidak ada perubahan yang tidak disengaja pada *resource* *cloud* produksi/asli.** | Karena LocalStack beroperasi dalam *container* terpisah, Anda dapat dengan aman menjalankan **`DELETE`** atau **`DROP`** perintah berbahaya untuk pengujian tanpa risiko merusak data atau infrastruktur di lingkungan **Staging** atau **Produksi** AWS yang asli. Ini menjaga integritas lingkungan yang sebenarnya. |


### 4. Instalasi dan Interaksi (Lanjutan ke Praktik)

#### A. Prasyarat Wajib ⚙️

1.  **Docker dan Docker Compose:** Digunakan untuk menjalankan *container* LocalStack.
2.  **AWS CLI:** Digunakan sebagai antarmuka untuk mengirim perintah ke LocalStack.

-----

#### B. Prosedur 1: Instalasi AWS CLI 📥

AWS CLI harus diinstal di **Host Machine** Anda agar dapat mengirim perintah ke LocalStack yang berjalan di Docker.

#### 1\. Instalasi di Linux (Ubuntu/Debian)

Gunakan metode *bundling* yang universal untuk mendapatkan AWS CLI v2:

```bash
# 1. Unduh bundel installer
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"

# 2. Unzip bundel (pastikan 'unzip' sudah terinstal)
sudo apt update && sudo apt install unzip -y
unzip awscliv2.zip

# 3. Jalankan instalasi
sudo ./aws/install
```

#### 2\. Verifikasi dan Konfigurasi Kredensial

  * **Verifikasi:** Cek versi AWS CLI yang terinstal.
    ```bash
    aws --version
    ```
  * **Konfigurasi Kredensial *Dummy*:** AWS CLI memerlukan *Access Key*. Gunakan nilai *dummy* karena kita tidak terhubung ke AWS publik.
    ```bash
    aws configure
    # AWS Access Key ID [None]: test
    # AWS Secret Access Key [None]: test
    # Default region name [None]: ap-southeast-1
    # Default output format [None]: json
    ```

-----

#### C. Prosedur 2: Menjalankan LocalStack dengan Docker Compose 🐳

Setelah AWS CLI siap, kita jalankan LocalStack sebagai *service* terisolasi.

#### 1\. File Konfigurasi: `docker-compose.yml`

Buat *file* ini untuk mendefinisikan *service* LocalStack dan *port* yang diekspos.

```yaml
version: '3.8'

services:
  localstack:
    image: localstack/localstack:latest
    container_name: localstack
    # Mapping Port 4566 (Wajib, untuk komunikasi API)
    ports:
      - "4566:4566"
    environment:
      # Daftarkan layanan inti yang diaktifkan (misalnya S3, Lambda, SQS)
      SERVICES: s3,lambda,sqs,sns
      DEFAULT_REGION: ap-southeast-1 
    volumes:
      # Volume untuk persistence data
      - "./localstack-data:/var/lib/localstack"
      # Mapping Docker Socket (Wajib untuk Lambda)
      - "/var/run/docker.sock:/var/run/docker.sock" 
```

#### 2\. Eksekusi dan Verifikasi

Jalankan perintah ini di *terminal Host* Anda, di direktori yang sama dengan `docker-compose.yml`.

```bash
# Menjalankan container di background
docker compose up -d

# Memeriksa log untuk memastikan service sudah siap
docker logs localstack
```

-----

#### D. Interaksi Awal: Kunci `--endpoint-url` 🔑

LocalStack sekarang berjalan di `http://localhost:4566`. Untuk berinteraksi, **setiap perintah AWS CLI harus diarahkan ke *endpoint* ini**.

| Tujuan Interaksi | Perintah AWS CLI |
| :--- | :--- |
| **Membuat Bucket S3 Lokal** | `aws s3api create-bucket --bucket my-first-local-bucket --region ap-southeast-1 --endpoint-url=http://localhost:4566` |
| **Memverifikasi Daftar Bucket** | `aws s3 ls --endpoint-url=http://localhost:4566` |
| **Membuat Queue SQS Lokal** | `aws sqs create-queue --queue-name my-test-queue --endpoint-url=http://localhost:4566` |



## 5. Hands-on: Menguji Interaksi LocalStack dan AWS CLI

Bagian praktik ini bertujuan untuk menguji koneksi antara **AWS CLI** yang terinstal di **Host Machine** Anda dengan **LocalStack** *container* yang berfungsi sebagai AWS tiruan. Pastikan **LocalStack sudah berjalan** (`docker compose up -d`) sebelum memulai.

### A. Kunci Utama: Pengarahan Endpoint

Ingat, setiap perintah harus menyertakan *flag* **`--endpoint-url=http://localhost:4566`** untuk mengarahkan permintaan ke LocalStack, bukan ke server AWS publik.

### B. Prosedur Hands-on S3 (Simple Storage Service)

Kita akan membuat *resource* (Bucket), memanipulasi isinya, dan membersihkan *resource* tersebut.

#### 1\. Persiapan File Uji

Buat *file* teks sederhana bernama `ujian.txt` di direktori kerja Anda sebagai data yang akan diunggah.

```bash
# Perintah untuk membuat file di Linux/macOS
echo "File ini diunggah ke S3 lokal menggunakan LocalStack." > ujian.txt

# Atau buat secara manual di Windows (misal: Notepad)
```

#### 2\. Membuat Bucket S3 (Storage)

Perintah ini akan membuat *bucket* S3, yang berfungsi seperti folder penyimpanan data di *Cloud* lokal Anda.

```bash
aws s3api create-bucket \
    --bucket projek-localstack-storage \
    --region ap-southeast-1 \
    --endpoint-url=http://localhost:4566
```

**Verifikasi:** Cek apakah *bucket* tersebut sudah terdaftar.

```bash
aws s3 ls --endpoint-url=http://localhost:4566
```

*Output yang diharapkan akan menampilkan `2025-11-25 10:00:00 projek-localstack-storage`*

-----

#### 3\. Mengunggah File ke Bucket

Gunakan perintah `cp` (*copy*) untuk menyalin file `ujian.txt` dari *Host* ke *Bucket* di LocalStack.

```bash
aws s3 cp ujian.txt s3://projek-localstack-storage/data/log/ujian-pertama.txt \
    --endpoint-url=http://localhost:4566
```

**Verifikasi Isi Bucket:** Cek apakah *object* (file) berhasil tersimpan.

```bash
aws s3 ls s3://projek-localstack-storage/data/log/ --endpoint-url=http://localhost:4566
```

*Output yang diharapkan akan menampilkan detail `ujian-pertama.txt`*

-----

#### 4\. Mengunduh dan Melihat File

Unduh file tersebut kembali ke *Host* dengan nama yang berbeda (`hasil_unduh.txt`) untuk membuktikan operasi berhasil.

```bash
aws s3 cp s3://projek-localstack-storage/data/log/ujian-pertama.txt hasil_unduh.txt \
    --endpoint-url=http://localhost:4566

# Periksa isinya di Host
cat hasil_unduh.txt
```

-----

#### 5\. Pembersihan (Cleanup)

Sebagai praktik terbaik DevOps (menjaga lingkungan tetap bersih), hapus *object* dan *bucket* yang telah dibuat.

**A. Hapus Object:**

```bash
aws s3 rm s3://projek-localstack-storage/data/log/ujian-pertama.txt \
    --endpoint-url=http://localhost:4566
```

**B. Hapus Bucket (hanya bisa jika kosong):**

```bash
aws s3api delete-bucket \
    --bucket projek-localstack-storage \
    --endpoint-url=http://localhost:4566
```


Meskipun fungsionalitasnya terbatas pada **operasi API metadata** di versi Komunitas (tanpa menjalankan VM sungguhan), *hands-on* ini penting untuk memahami bagaimana **AWS CLI** berinteraksi dengan layanan *compute* di LocalStack.

---

## 6. Hands-on: Menguji Interaksi LocalStack dengan EC2

Tujuan dari *hands-on* ini adalah untuk menguji *command* pembuatan dan pengelolaan *instance* EC2 pada level API, bukan pada eksekusi mesin virtual yang sebenarnya.

#### A. Konsep Dasar EC2 di LocalStack (Komunitas) 🛑

Di LocalStack versi Komunitas, saat Anda menjalankan perintah EC2:

* LocalStack akan **mencatat dan mengonfirmasi** operasi tersebut.
* Anda akan mendapatkan **Instance ID** yang valid dan status metadata.
* **Namun, tidak ada VM Linux/Windows sungguhan yang dibuat** atau di-*boot* di *Host* Anda.

#### B. Prosedur Hands-on EC2 Metadata

Pastikan LocalStack berjalan (`docker compose up -d`) dan Anda selalu menyertakan *flag* `--endpoint-url=http://localhost:4566`.

| Langkah | Perintah AWS CLI | Tujuan |
| :--- | :--- | :--- |
| **1. Melihat Daftar Awal** | ```bash aws ec2 describe-instances --endpoint-url=http://localhost:4566 ``` | Memverifikasi bahwa belum ada *instance* EC2 yang terdaftar di LocalStack. (Output harus kosong atau tidak ada *Reservation*). |
| **2. Membuat Instance EC2 (Metadata)** | ```bash aws ec2 run-instances \ --image-id ami-0123456789abcdef0 \ --count 1 \ --instance-type t2.micro \ --key-name my-test-key \ --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=LocalStack-DevServer}]' \ --endpoint-url=http://localhost:4566 ``` | **Mengirim permintaan API** untuk membuat satu *instance*. Perintah ini akan segera mengembalikan *Instance ID* dan detail konfigurasi. (Perhatikan: *Image ID* `ami-0123...` hanya *dummy*). |
| **3. Mencatat Instance ID** | Setelah langkah 2, catat **Instance ID** yang dikembalikan (misalnya, `i-01a2b3c4d5e6f7g8h`). Simpan ID ini dalam variabel *shell* jika memungkinkan. | ID ini adalah pengenal unik VM Anda di LocalStack. |
| **4. Verifikasi Status Instance** | ```bash aws ec2 describe-instances --instance-ids [ID_ANDA] --endpoint-url=http://localhost:4566 ``` | Memeriksa status dan metadata *instance* yang baru dibuat (Status akan tercatat sebagai `running` atau `pending` di LocalStack). |
| **5. Menghentikan Instance** | ```bash aws ec2 stop-instances --instance-ids [ID_ANDA] --endpoint-url=http://localhost:4566 ``` | Mengirim perintah API untuk mengubah status *instance* menjadi `stopped`. |
| **6. Membersihkan (Terminate)** | ```bash aws ec2 terminate-instances --instance-ids [ID_ANDA] --endpoint-url=http://localhost:4566 ``` | Mengirim perintah API untuk **menghapus permanen** metadata *instance* dari LocalStack. |

#### C. Penting: Verifikasi Pembersihan

Setelah langkah 6, ulangi `aws ec2 describe-instances` (Langkah 4). Status *instance* harus tercatat sebagai **`terminated`** dan tidak akan muncul dalam daftar *instance* aktif. Ini membuktikan bahwa operasi EC2 API telah berhasil diemulasi dan LocalStack telah membersihkan catatannya.