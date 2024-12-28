package com.nothingnessn.wallpaperdesing;

import android.app.WallpaperManager;
import android.content.res.AssetManager;
import android.os.Bundle;
import android.util.Log;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import androidx.annotation.NonNull;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.FileInputStream;

public class MainActivity extends FlutterActivity {
    private static final String CHANNEL = "com.nothingnessn.wallpaperdesing";

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
            .setMethodCallHandler(
                (call, result) -> {
                    if (call.method.equals("setWallpaper")) {
                        String filePath = call.argument("filePath");
                        if (filePath != null) {
                            setWallpaper(filePath, result);
                        } else {
                            result.error("INVALID_ARGUMENT", "File path is required", null);
                        }
                    } else {
                        result.notImplemented();
                    }
                }
            );
    }

    private void setWallpaper(String filePath, MethodChannel.Result result) {
        File tempFile = new File(getCacheDir(), new File(filePath).getName());

        try {
            // Dosya yoluna göre geçici dosyaya kopyalama
            try (InputStream inputStream = new FileInputStream(new File(filePath));
                 FileOutputStream outputStream = new FileOutputStream(tempFile)) {
                byte[] buffer = new byte[1024];
                int read;
                while ((read = inputStream.read(buffer)) != -1) {
                    outputStream.write(buffer, 0, read);
                }
                Log.d("MainActivity", "File copied to temp file.");
            }

            // Duvar kağıdını ayarlama
            WallpaperManager wallpaperManager = WallpaperManager.getInstance(this);
            try (FileInputStream tempInputStream = new FileInputStream(tempFile)) {
                wallpaperManager.setStream(tempInputStream);
                Log.d("MainActivity", "Wallpaper set successfully.");
            }

            // Geçici dosyayı silme
            if (tempFile.exists()) {
                tempFile.delete();
            }

            result.success(null);
        } catch (IOException e) {
            Log.e("MainActivity", "Failed to set wallpaper. File: " + filePath + ". Error: " + e.getMessage(), e);
            result.error("IO_EXCEPTION", "Error setting wallpaper: " + e.getMessage(), null);
        }
    }
}
