# Rubrik Penilaian 🏆

Rubrik ini dirancang agar komprehensif, sistematis, detail, dan logis, dengan bobot yang tinggi pada aspek keamanan dan kontrol alur (*workflow*).

| Kriteria Penilaian | Bobot | Level 1 (Cukup: 60-75) | Level 2 (Baik: 76-85) | Level 3 (Sangat Baik: 86-100) |
| :--- | :--- | :--- | :--- | :--- |
| **I. Keamanan & Kredensial (PoLP)** | **40%** | Token K8s (`KUBE_TOKEN`) diimplementasikan, tetapi *RoleBinding* tidak optimal (izin terlalu luas). | **+ Implementasi Trivy Scan** sebagai *Quality Gate* (exit code 1) di `.drone.yml`. | **+ Implementasi ImagePullSecret** berhasil dikonfigurasi di K8s, dan **RBAC terbukti minimal** (misalnya, *deployer* tidak bisa *delete* *namespace*). |
| **II. Kontrol Alur (Workflow)** | **30%** | *Pipeline* berjalan otomatis dari 1 *branch* (`main`) dan hanya menargetkan *namespace* **`dev`**. | **+ Implementasi GitLab Flow:** *Pipeline* memiliki 2 *step* *Deployment* berbeda yang dipicu oleh 2 *branch* berbeda (`main` → `dev`, `staging` → `staging`). | **+ Implementasi Manual Approval:** *Deployment* ke *namespace* **`staging`** menggunakan kondisi **`trigger: manual`**. |
| **III. Stages & Tools (Kelengkapan Pipeline)** | **20%** | *Pipeline* hanya mencakup Stage Build, Publish, dan Deploy. *Image* berhasil di-*push*. | **+ Pipeline lengkap:** Mencakup Stage Build, Publish, **Scan (Trivy)**, dan Deploy. | **+ Pengujian Kegagalan:** Mahasiswa menyajikan *screenshot* yang membuktikan *pipeline* **gagal** ketika *Scan* mendeteksi kerentanan kritis. |
| **IV. Dokumentasi & Presentasi (Kelompok)** | **10%** | Menyajikan *file* `.drone.yml` dan *screenshot* *pipeline* berhasil. | **+ Dokumentasi Teknis Sistematis:** Menyertakan skema *end-to-end* *flowchart* dan penjelasan logis per *step*. | **+ Analisis & Troubleshooting:** Menjelaskan *troubleshooting* kegagalan SSL Harbor dan *ImagePullBackOff*, serta **presentasi kolaboratif** yang efektif. |
