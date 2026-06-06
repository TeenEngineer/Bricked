package com.teen.bricked

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import android.widget.Button
import android.widget.TextView

class LockScreenActivity : Activity() {
    private var packageName: String? = null
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        packageName = intent.getStringExtra("package_name")
        
        // Create a simple lock screen UI
        val layout = android.widget.LinearLayout(this).apply {
            orientation = android.widget.LinearLayout.VERTICAL
            setPadding(50, 50, 50, 50)
            setBackgroundColor(0xFF2196F3.toInt())
        }
        
        val titleText = TextView(this).apply {
            text = "App Locked"
            textSize = 24f
            setTextColor(0xFFFFFFFF.toInt())
            gravity = android.view.Gravity.CENTER
        }
        
        val messageText = TextView(this).apply {
            text = "This app is locked. Tap your NFC tag to unlock it."
            textSize = 16f
            setTextColor(0xFFFFFFFF.toInt())
            gravity = android.view.Gravity.CENTER
            setPadding(0, 20, 0, 20)
        }
        
        val appNameText = TextView(this).apply {
            text = "Package: $packageName"
            textSize = 14f
            setTextColor(0xFFFFFFFF.toInt())
            gravity = android.view.Gravity.CENTER
            setPadding(0, 0, 0, 30)
        }
        
        val closeButton = Button(this).apply {
            text = "Close"
            setOnClickListener {
                finish()
                // Go to home screen
                val homeIntent = Intent(Intent.ACTION_MAIN).apply {
                    addCategory(Intent.CATEGORY_HOME)
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                }
                startActivity(homeIntent)
            }
        }
        
        layout.addView(titleText)
        layout.addView(messageText)
        layout.addView(appNameText)
        layout.addView(closeButton)
        
        setContentView(layout)
    }
}
