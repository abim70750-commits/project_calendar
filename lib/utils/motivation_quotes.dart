import 'dart:math';

class MotivationQuotes {
  static const List<String> quotes = [
    'Mulai aja dulu, sempurna belakangan.',
    'Satu langkah kecil hari ini, satu project selesai nanti.',
    'Deadline itu teman, bukan musuh.',
    'Jangan tunggu mood, bangun disiplin.',
    'Progres kecil tetap progres.',
    'Fokus. Kerjakan. Selesaikan.',
    'Hari ini kamu yang atur, bukan rasa malas.',
    'Capek boleh, menyerah jangan.',
    'Yang kamu tunda hari ini jadi beban besok.',
    'Kerjakan sekarang, tenang kemudian.',
    'Kamu lebih kuat dari alasanmu.',
    'Selesai lebih baik daripada sempurna.',
    'Bikin satu centang hari ini.',
    'Konsisten ngalahin motivasi.',
    'Target besar dimulai dari tugas kecil.',
    'Jangan bandingkan start-mu dengan finish orang lain.',
    'Waktu jalan terus, ayo ikut jalan.',
    'Kerja keras hari ini, bangga besok.',
    'Pecah masalah besar jadi langkah kecil.',
    'Gagal itu data, bukan akhir.',
    'Mulai sekarang, bukan nanti.',
    'Sejam fokus lebih berharga dari sehari rebahan.',
    'Kamu pernah lewatin hari yang lebih berat.',
    'Disiplin itu bentuk sayang ke diri sendiri.',
    'Jangan biarin deadline ngejar kamu.',
    'Tuntaskan satu hal, rasain leganya.',
    'Rencana tanpa aksi cuma angan-angan.',
    'Pelan-pelan asal kelar.',
    'Hari ini milikmu, pakai dengan bijak.',
    'Project kelar, hati tenang.',
  ];

  static final Random _rng = Random();

  static String random() => quotes[_rng.nextInt(quotes.length)];
}
