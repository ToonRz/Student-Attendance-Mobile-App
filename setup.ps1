Write-Host "🚀 Starting setup for Student Attendance Mobile App..." -ForegroundColor Cyan

# 1. Setup Backend
Write-Host "`n📦 Setting up Backend..." -ForegroundColor Yellow
Set-Location -Path "backend"
if (Test-Path "package.json") {
    Write-Host "Installing dependencies..."
    npm install
    
    Write-Host "Generating Prisma Client..."
    npx prisma generate
    
    Write-Host "Updating Database Schema..."
    npx prisma db push
    
    Write-Host "✅ Backend setup complete!" -ForegroundColor Green
} else {
    Write-Host "❌ Backend folder or package.json not found!" -ForegroundColor Red
}

Set-Location -Path ".."

# 2. Setup Mobile (Flutter)
Write-Host "`n📱 Setting up Mobile App (Flutter)..." -ForegroundColor Yellow
Set-Location -Path "mobile"

# Create native platforms if they don't exist
if (-not (Test-Path "android") -or -not (Test-Path "ios")) {
    Write-Host "Generating iOS and Android platform folders..."
    flutter create --org com.studentattendance --project-name student_attendance --platforms android,ios .
}

# Update Android permissions
$manifestPath = "android/app/src/main/AndroidManifest.xml"
if (Test-Path $manifestPath) {
    Write-Host "Adding Android camera and location permissions..."
    $manifestContent = Get-Content $manifestPath -Raw
    
    $permissions = @"
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.CAMERA" />
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
"@
    
    if (-not $manifestContent.Contains("android.permission.CAMERA")) {
        $manifestContent = $manifestContent -replace '<manifest.*?>', "`$0`n$permissions"
        Set-Content -Path $manifestPath -Value $manifestContent
    }
}

# Update iOS permissions
$plistPath = "ios/Runner/Info.plist"
if (Test-Path $plistPath) {
    Write-Host "Adding iOS camera and location permissions..."
    $plistContent = Get-Content $plistPath -Raw
    
    $iosPermissions = @"
	<key>NSCameraUsageDescription</key>
	<string>This app needs camera access to scan QR codes for attendance.</string>
	<key>NSLocationWhenInUseUsageDescription</key>
	<string>This app needs your location to verify you are in the classroom when checking in.</string>
	<key>NSLocationAlwaysUsageDescription</key>
	<string>This app needs your location to verify attendance.</string>
"@
    
    if (-not $plistContent.Contains("NSCameraUsageDescription")) {
        $plistContent = $plistContent -replace '<dict>', "`$0`n$iosPermissions"
        Set-Content -Path $plistPath -Value $plistContent
    }
}

Write-Host "Getting Flutter dependencies..."
flutter pub get

Write-Host "✅ Mobile setup complete!" -ForegroundColor Green

Write-Host "`n🎉 Setup Finished Successfully!" -ForegroundColor Cyan
Write-Host "To start the backend, run: cd backend && npm run dev"
Write-Host "To start the app, run: cd mobile && flutter run"
