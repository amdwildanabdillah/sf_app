#!/bin/bash

echo "🚀 Membuat file .env di server Vercel..."
# Script ini akan membuat file .env dadakan saat proses build
echo "SUPABASE_URL=$SUPABASE_URL" > .env
echo "SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY" >> .env
echo "✅ File .env berhasil dibuat!"

echo "🚀 Cek Flutter..."
if cd flutter; then
  git pull && cd ..
else
  git clone https://github.com/flutter/flutter.git -b stable flutter
fi

echo "✅ Flutter Siap. Mulai Build..."
flutter/bin/flutter config --enable-web
flutter/bin/flutter clean
flutter/bin/flutter pub get
flutter/bin/flutter build web --release
echo "🎉 Build Selesai!"