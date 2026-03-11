## Vagrant
gitea dan drone ci nya jgn di vm mending taro di docker windows aj jadi runningnya dia  
### 1. Definisi dan Tujuan Vagrant 🎯

#### 1.1. Apa itu Vagrant?

**Vagrant** adalah perangkat lunak *open-source* (sumber terbuka) yang berfungsi sebagai **manajer lingkungan pengembangan virtual**.

Secara teknis, Vagrant adalah lapisan abstrak (abstrak *layer*) yang berada di atas *provider* virtualisasi seperti VirtualBox, VMWare, atau Hyper-V. Ia mengubah cara kita berinteraksi dengan Mesin Virtual (VM).

* **Fokus Inti:** Mengotomasi dan menyederhanakan siklus hidup VM, mulai dari pembuatan, konfigurasi, hingga penghancuran.

#### 1.2. Tujuan Utama Penggunaan Vagrant

Tujuan utama penggunaan Vagrant dalam konteks pengembangan *software* modern—dan khususnya dalam *setup* CI/CD kita—dapat diringkas sebagai berikut:

| No. | Tujuan | Penjelasan Mendalam |
| :--- | :--- | :--- |
| **1.** | **Menghilangkan Konflik Lingkungan (No More "Works on My Machine!")** | Setiap *developer* atau mahasiswa akan memiliki VM yang **100% identik** dengan konfigurasi OS, *resource* (RAM/CPU), dan *tools* (Docker, Git). Ini menghilangkan masalah perbedaan lingkungan antara mesin lokal, pengujian, atau produksi. |
| **2.** | **Lingkungan yang Dapat Direplikasi (*Reproducible*)** | Vagrant memastikan bahwa lingkungan dapat dibuat ulang dari awal kapan saja dan di mana saja hanya dengan satu perintah (`vagrant up`). Konfigurasi ini diabadikan dalam *file* tunggal bernama **`Vagrantfile`**. |
| **3.** | **Penyederhanaan Proses *Setup*** | Daripada menginstal OS, mengalokasikan RAM, menginstal Docker, dan mengatur jaringan secara manual berjam-jam, Vagrant menyelesaikan semua langkah ini secara otomatis, membuat lingkungan siap dalam hitungan menit. |
| **4.** | **Infrastruktur sebagai Kode (IaC)** | Konfigurasi infrastruktur (seperti VM, jaringan, dan instalasi *software*) ditulis dalam bentuk kode (Ruby) di `Vagrantfile`. Ini memfasilitasi *version control* dan kolaborasi tim. |

---

## 2. Konsep Kunci dalam Vagrant

Memahami empat konsep utama ini sangat penting untuk dapat mengelola dan memecahkan masalah lingkungan Vagrant.

### 2.1. `Vagrantfile`

`Vagrantfile` adalah **jantung** dari setiap proyek Vagrant.

| Detail | Fungsi dan Makna | Contoh Implementasi Kritis |
| :--- | :--- | :--- |
| **Definisi** | Sebuah *file* konfigurasi yang ditulis dalam bahasa **Ruby** (meskipun sintaksnya mudah dibaca bahkan tanpa pengetahuan Ruby). | Menentukan *blueprint* lengkap dari Mesin Virtual (VM). |
| **Fungsi Kritis** | Mendefinisikan **OS** (`config.vm.box`), **Jaringan Statis** (`private_network`), dan **Alokasi Sumber Daya** (RAM/CPU). | Tanpa `Vagrantfile` yang benar, VM tidak akan bisa berjalan atau berkomunikasi dengan layanan lain (Gitea/Drone/Harbor). |

### 2.2. Box

*Box* adalah *image* atau **cetak biru** dari sistem operasi dasar yang akan digunakan Vagrant untuk membuat VM.

| Detail | Fungsi dan Makna | Contoh Implementasi Kritis |
| :--- | :--- | :--- |
| **Definisi** | Paket yang telah dikemas sebelumnya yang berisi OS minimal dan konfigurasi untuk *provider* tertentu (misalnya, VirtualBox). | Contoh: **`ubuntu/focal64`** (Ubuntu 20.04 LTS). |
| **Fungsi Kritis** | Memastikan *starting point* yang **konsisten**. Setiap kali Anda menjalankan `vagrant up`, *box* yang sama digunakan, menjamin keseragaman lingkungan. | Menghemat waktu *setup* OS. Jika *box* sudah diunduh, ia akan di-*cache* dan tidak perlu diunduh lagi. |

### 2.3. Provider

*Provider* adalah **mesin** virtualisasi sesungguhnya yang menjalankan VM Anda.

| Detail | Fungsi dan Makna | Contoh Implementasi Kritis |
| :--- | :--- | :--- |
| **Definisi** | Perangkat lunak yang menjalankan VM di komputer Host Anda. | Contoh: **VirtualBox** (paling umum), VMWare, Hyper-V, atau *cloud provider* (AWS, Azure). |
| **Fungus Kritis** | Vagrant berinteraksi dengan *provider* melalui API. Dalam `Vagrantfile`, kita dapat menggunakan *provider* VirtualBox (`config.vm.provider "virtualbox"`) untuk mengatur detail *low-level* seperti **RAM** (`--memory`) dan **CPU** (`--cpus`). | **Vagrant mengabstraksi *provider***, memungkinkan Anda beralih dari VirtualBox ke VMWare tanpa mengubah *syntax* `Vagrantfile` secara drastis. |

### 2.4. Provisioning

*Provisioning* adalah mekanisme untuk **menginstal *software* atau mengkonfigurasi sistem** secara otomatis *setelah* VM dibuat.

| Detail | Fungsi dan Makna | Contoh Implementasi Kritis |
| :--- | :--- | :--- |
| **Definisi** | Menjalankan *script* (*shell*, Ansible, Chef, dll.) di dalam VM saat proses `vagrant up` pertama kali. | Digunakan untuk memastikan VM siap pakai untuk kebutuhan spesifik (misalnya, menjadi Host CI/CD). |
| **Fungsi Kritis** | **Automasi Instalasi *Tools***: Dalam modul kita, *provisioning* digunakan untuk menginstal **Docker**, **Docker Compose**, dan menambahkan *user* ke grup `docker` menggunakan *script* **`setup.sh`**. | Menghilangkan kebutuhan untuk masuk (`vagrant ssh`) dan menginstal *tools* secara manual, mempercepat *setup* lingkungan kerja. |

Keempat konsep ini bekerja sama untuk membangun **Host CI/CD** (`10.0.0.50`) Anda secara otomatis, dari pemilihan OS hingga instalasi *tools* yang dibutuhkan.

---

## 3. Fungsi Vagrant dalam Lingkungan Virtualisasi

Vagrant berperan penting dalam menyediakan fondasi teknis yang andal untuk lingkungan pengujian atau pengembangan apa pun.

### A. Alokasi Sumber Daya (Resource Isolation) 🧠

Pengaturan *resource* yang eksplisit penting untuk menjamin kinerja *server* virtual, terutama saat menjalankan layanan yang membutuhkan memori tinggi.

  * **Requirement:** Setiap layanan *server* (misalnya, *web server*, *database*, atau *middleware*) membutuhkan jaminan RAM dan CPU agar dapat beroperasi tanpa terganggu oleh Host Machine atau *resource contention* lain.
  * **Solusi Vagrant:** Vagrant memungkinkan kita mendefinisikan *resource* minimum menggunakan bagian `config.vm.provider` untuk *provider* seperti VirtualBox.

#### Konfigurasi Kritis di `Vagrantfile`:

```ruby
config.vm.provider "virtualbox" do |vb|
  # ...
  # Alokasi RAM (4 GB)
  vb.customize ["modifyvm", :id, "--memory", "4096"] 
  # Alokasi CPU (2 Core)
  vb.customize ["modifyvm", :id, "--cpus", "2"] 
end
```

  * **Fungsi:** Konfigurasi ini **mengisolasi** sumber daya dari Host Machine, menjamin VM akan selalu memiliki *resource* yang dialokasikan, mencegah kegagalan *runtime* yang disebabkan oleh kekurangan memori (*Out-of-Memory error*).

-----

### B. Jaringan Statis (Network Stability) 🌐

Stabilitas jaringan VM sangat penting agar Host Machine dapat berinteraksi secara konsisten dengan layanan di dalam VM.

  * **Requirement:** Untuk pengujian *server* atau API, *developer* membutuhkan alamat IP yang **pasti, statis, dan tidak berubah** agar konfigurasi koneksi *server-to-server* atau koneksi dari Host tidak perlu diubah-ubah.
  * **Solusi Vagrant:** Vagrant menyediakan fitur **`private_network`** untuk membuat adaptor jaringan internal (*Host-Only Network*) dengan IP yang ditentukan.

#### Konfigurasi Kritis di `Vagrantfile`:

```ruby
# Menetapkan alamat IP VM secara statis
config.vm.network "private_network", ip: "10.0.0.50"
```

  * **Fungsi:** Alamat **`10.0.0.50`** (contoh) menjadi identitas permanen VM tersebut. Ini sangat vital untuk:
    1.  **Akses Host:** Host Machine dapat mengakses *service* di VM menggunakan IP ini secara langsung.
    2.  **Stabilitas Konfigurasi:** Mencegah perubahan IP dinamis, yang akan merusak *script* atau konfigurasi internal yang bergantung pada alamat jaringan tetap.


---


## 4. Perintah Dasar Vagrant (Alur Kerja)

Perintah-perintah ini adalah kunci untuk berinteraksi dengan **Vagrantfile** dan VM Anda di setiap fase proyek. Semua perintah ini dijalankan di **Command Prompt/Terminal Host** Anda, di dalam direktori tempat `Vagrantfile` berada.

| Perintah | Deskripsi Fungsi | Detail dan Contoh Penggunaan |
| :--- | :--- | :--- |
| **`vagrant up`** | **Menciptakan dan Menghidupkan VM.** | Perintah pertama yang dijalankan. Ini akan membaca `Vagrantfile`, mengunduh *Box* jika belum ada, membuat VM di VirtualBox, mengatur jaringan (`10.0.0.50`), dan menjalankan *script provisioning* (`setup.sh`). Setelah VM dimatikan, `vagrant up` hanya akan menghidupkannya kembali. |
| **`vagrant ssh`** | **Akses ke Terminal VM.** | Digunakan untuk masuk ke dalam *Host* VM (`10.0.0.50`) melalui koneksi SSH. Di sinilah Anda akan bekerja untuk menginstal layanan (Gitea, Drone, Harbor) dan mengelola *container* Docker. |
| **`vagrant reload`** | **Memuat Ulang Konfigurasi VM.** | Wajib dijalankan setelah Anda memodifikasi **`Vagrantfile`** (misalnya, mengubah alokasi **RAM** atau **CPU**). Perintah ini akan mematikan VM, menerapkan perubahan konfigurasi di VirtualBox, dan menghidupkannya kembali. |
| **`vagrant provision`** | **Menjalankan Ulang *Provisioning***. | Jika Anda mengubah isi *script* `setup.sh` (atau *script* *provisioning* lainnya), Anda bisa menjalankan perintah ini untuk mengeksekusi *script* tersebut tanpa memuat ulang VM secara keseluruhan. |
| **`vagrant halt`** | **Mematikan VM secara Aman.** | Melakukan *shutdown* yang aman pada VM. VM tidak dihapus dan dapat dihidupkan kembali dengan cepat menggunakan `vagrant up`. |
| **`vagrant destroy`** | **Menghapus Total VM.** | Perintah ini **menghapus secara permanen** VM dari VirtualBox dan semua *file* VM yang terkait. Gunakan ini untuk membersihkan lingkungan setelah proyek selesai atau untuk *troubleshoot* masalah yang parah. |

### Alur Kerja Umum (Workflow)

Mahasiswa biasanya akan mengikuti urutan perintah ini saat bekerja:

1.  **Mulai Kerja:** `vagrant up`
2.  **Akses Host:** `vagrant ssh`
3.  **Saat Mengubah RAM/CPU:** `vagrant reload`
4.  **Selesai Kerja:** `vagrant halt`
5.  **Bersihkan Lingkungan:** `vagrant destroy`

---