package com.nl.nltime

import android.app.*
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.text.Spannable
import android.text.SpannableStringBuilder
import android.text.style.ForegroundColorSpan
import android.text.style.RelativeSizeSpan
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.widget.LinearLayout
import android.widget.TextView
import androidx.core.app.NotificationCompat
import java.text.SimpleDateFormat
import java.util.*

class FloatClockService : Service() {

    private var windowManager: WindowManager? = null
    private var containerView: LinearLayout? = null
    private var fullLayout: LinearLayout? = null
    private var miniLayout: LinearLayout? = null
    
    private var fullTimeTv: TextView? = null
    private var miniTimeTv: TextView? = null
    private var subTextView: TextView? = null
    private var sourceBadgeTv: TextView? = null
    private var dotView: View? = null
    private var titleTv: TextView? = null
    private var miniIconTv: TextView? = null
    private var minBtn: TextView? = null
    private var expandBtn: TextView? = null
    private var closeBtn: TextView? = null
    
    private var handler: Handler? = null
    private var runnable: Runnable? = null
    private var isMinimized = false

    companion object {
        var isRunning = false
        var instance: FloatClockService? = null

        var timeOffsetMs: Long = 0
        var rttMs: Int = 0
        var sourceName: String = "苏宁时间"
        var showMs: Boolean = true
        var showOffset: Boolean = true
        var showSource: Boolean = true
        var opacity: Float = 0.9f
        var scale: Float = 1.0f
        var themeIdx: Int = 0

        const val CHANNEL_ID = "nltime_float_channel"
        const val NOTIFICATION_ID = 1001

        fun updateParams(
            offsetMs: Long,
            rtt: Int,
            source: String,
            showMsVal: Boolean,
            showOffsetVal: Boolean,
            showSourceVal: Boolean,
            opacityVal: Float,
            scaleVal: Float,
            themeIndex: Int
        ) {
            timeOffsetMs = offsetMs
            rttMs = rtt
            sourceName = source
            showMs = showMsVal
            showOffset = showOffsetVal
            showSource = showSourceVal
            opacity = opacityVal
            scale = scaleVal
            themeIdx = themeIndex
        }

        fun applyParamsUpdate() {
            instance?.updateUIThemeAndScale()
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        isRunning = true
        instance = this
        createNotificationChannel()
        startForeground(NOTIFICATION_ID, buildNotification())
        initFloatWindow()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "极速对时悬浮服务",
                NotificationManager.IMPORTANCE_LOW
            )
            channel.description = "保证全局毫秒悬浮窗在后台稳定运行"
            val manager = getSystemService(NotificationManager::class.java)
            manager?.createNotificationChannel(channel)
        }
    }

    private fun buildNotification(): Notification {
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("极速对时悬浮窗口运行中")
            .setContentText("全局毫秒网络时钟悬浮置顶中")
            .setSmallIcon(android.R.drawable.ic_menu_compass)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setOngoing(true)
            .build()
    }

    private fun getThemeColors(): ThemeColors {
        return when (themeIdx) {
            1 -> ThemeColors(
                cardColor = "#EE1B1633",
                primaryColor = "#FF2A85",
                textColor = "#FFFFFF",
                subTextColor = "#A78BFA"
            )
            2 -> ThemeColors(
                cardColor = "#EEFFFFFF",
                primaryColor = "#4F46E5",
                textColor = "#0F172A",
                subTextColor = "#64748B"
            )
            3 -> ThemeColors(
                cardColor = "#EE102820",
                primaryColor = "#00E676",
                textColor = "#FFFFFF",
                subTextColor = "#6EE7B7"
            )
            else -> ThemeColors(
                cardColor = "#EE131A2A",
                primaryColor = "#00E5FF",
                textColor = "#FFFFFF",
                subTextColor = "#94A3B8"
            )
        }
    }

    data class ThemeColors(
        val cardColor: String,
        val primaryColor: String,
        val textColor: String,
        val subTextColor: String
    )

    private fun initFloatWindow() {
        windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager

        val layoutType = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        } else {
            @Suppress("DEPRECATION")
            WindowManager.LayoutParams.TYPE_PHONE
        }

        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            layoutType,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                    WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or
                    WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
            PixelFormat.TRANSLUCENT
        )

        params.gravity = Gravity.TOP or Gravity.START
        params.x = dp2px(20)
        params.y = dp2px(120)

        // Main outer container
        containerView = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
        }

        // --- FULL CONTENT LAYOUT ---
        fullLayout = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
        }

        // Header Row (Full)
        val headerLayout = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
        }

        dotView = View(this).apply {
            layoutParams = LinearLayout.LayoutParams(dp2px(8), dp2px(8)).apply {
                rightMargin = dp2px(6)
            }
        }

        titleTv = TextView(this).apply {
            text = "极速对时"
            typeface = Typeface.DEFAULT_BOLD
            layoutParams = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f)
        }

        minBtn = TextView(this).apply {
            text = " ↙ "
            typeface = Typeface.DEFAULT_BOLD
            setOnClickListener {
                isMinimized = true
                updateVisibilityMode()
            }
        }

        closeBtn = TextView(this).apply {
            text = " ✕ "
            setTextColor(Color.parseColor("#FF5252"))
            typeface = Typeface.DEFAULT_BOLD
            setOnClickListener {
                stopSelf()
            }
        }

        headerLayout.addView(dotView)
        headerLayout.addView(titleTv)
        headerLayout.addView(minBtn)
        headerLayout.addView(closeBtn)
        fullLayout?.addView(headerLayout)

        // Full Time TextView
        fullTimeTv = TextView(this).apply {
            typeface = Typeface.MONOSPACE
            setTypeface(typeface, Typeface.BOLD)
        }
        fullLayout?.addView(fullTimeTv)

        // Sub Info Row (Source badge + Offset/RTT text)
        val subInfoRow = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
        }

        sourceBadgeTv = TextView(this).apply {
            typeface = Typeface.DEFAULT_BOLD
        }

        subTextView = TextView(this)

        subInfoRow.addView(sourceBadgeTv)
        subInfoRow.addView(subTextView)
        fullLayout?.addView(subInfoRow)

        // --- MINI CONTENT LAYOUT ---
        miniLayout = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            visibility = View.GONE
        }

        miniIconTv = TextView(this).apply {
            text = "⏱ "
        }

        miniTimeTv = TextView(this).apply {
            typeface = Typeface.MONOSPACE
            setTypeface(typeface, Typeface.BOLD)
        }

        expandBtn = TextView(this).apply {
            text = " ↗ "
            typeface = Typeface.DEFAULT_BOLD
            setOnClickListener {
                isMinimized = false
                updateVisibilityMode()
            }
        }

        miniLayout?.addView(miniIconTv)
        miniLayout?.addView(miniTimeTv)
        miniLayout?.addView(expandBtn)

        containerView?.addView(fullLayout)
        containerView?.addView(miniLayout)

        updateUIThemeAndScale()

        // Touch Listener on containerView ONLY (WRAP_CONTENT bounds)
        containerView?.setOnTouchListener(object : View.OnTouchListener {
            private var initialX = 0
            private var initialY = 0
            private var initialTouchX = 0f
            private var initialTouchY = 0f

            override fun onTouch(v: View?, event: MotionEvent?): Boolean {
                event ?: return false
                when (event.action) {
                    MotionEvent.ACTION_DOWN -> {
                        initialX = params.x
                        initialY = params.y
                        initialTouchX = event.rawX
                        initialTouchY = event.rawY
                        return true
                    }
                    MotionEvent.ACTION_MOVE -> {
                        params.x = initialX + (event.rawX - initialTouchX).toInt()
                        params.y = initialY + (event.rawY - initialTouchY).toInt()
                        windowManager?.updateViewLayout(containerView, params)
                        return true
                    }
                }
                return false
            }
        })

        windowManager?.addView(containerView, params)

        // Handler timer for 16ms high frequency millisecond update
        handler = Handler(Looper.getMainLooper())
        val dateFormatSec = SimpleDateFormat("HH:mm:ss", Locale.getDefault())

        runnable = object : Runnable {
            override fun run() {
                val nowMs = System.currentTimeMillis() + timeOffsetMs
                val date = Date(nowMs)

                val secStr = dateFormatSec.format(date)
                val msVal = if (showMs) {
                    // Show full 3-digit milliseconds (.SSS) when switch is ON
                    String.format(Locale.getDefault(), ".%03d", (nowMs % 1000).toInt())
                } else {
                    // Default: 1-digit millisecond (.S)
                    val msDigit = ((nowMs % 1000) / 100).toInt()
                    ".$msDigit"
                }

                val colors = getThemeColors()
                val mainTextColor = Color.parseColor(colors.textColor)
                val primaryThemeColor = Color.parseColor(colors.primaryColor)

                val spannable = SpannableStringBuilder(secStr + msVal)
                // Main time (HH:mm:ss) in main textColor
                spannable.setSpan(
                    ForegroundColorSpan(mainTextColor),
                    0,
                    secStr.length,
                    Spannable.SPAN_EXCLUSIVE_EXCLUSIVE
                )
                // Milliseconds (.S or .SSS) in vibrant primaryThemeColor and 0.75x font size
                spannable.setSpan(
                    ForegroundColorSpan(primaryThemeColor),
                    secStr.length,
                    spannable.length,
                    Spannable.SPAN_EXCLUSIVE_EXCLUSIVE
                )
                spannable.setSpan(
                    RelativeSizeSpan(0.75f),
                    secStr.length,
                    spannable.length,
                    Spannable.SPAN_EXCLUSIVE_EXCLUSIVE
                )
                fullTimeTv?.text = spannable

                miniTimeTv?.text = secStr

                sourceBadgeTv?.text = sourceName
                sourceBadgeTv?.visibility = if (showSource) View.VISIBLE else View.GONE

                val offsetSec = timeOffsetMs / 1000.0
                subTextView?.text = String.format(Locale.getDefault(), "偏差: %.2fs | RTT: %dms", offsetSec, rttMs)
                subTextView?.visibility = if (showOffset) View.VISIBLE else View.GONE

                containerView?.alpha = opacity

                handler?.postDelayed(this, 16)
            }
        }
        handler?.post(runnable!!)
    }

    private fun updateVisibilityMode() {
        if (isMinimized) {
            fullLayout?.visibility = View.GONE
            miniLayout?.visibility = View.VISIBLE
        } else {
            fullLayout?.visibility = View.VISIBLE
            miniLayout?.visibility = View.GONE
        }
    }

    private fun updateUIThemeAndScale() {
        val colors = getThemeColors()
        val cardBgColor = Color.parseColor(colors.cardColor)
        val primaryColor = Color.parseColor(colors.primaryColor)
        val textColor = Color.parseColor(colors.textColor)
        val subTextColor = Color.parseColor(colors.subTextColor)

        val s = scale.coerceIn(0.5f, 2.5f)

        // Real-time padding update
        val pad = dp2px((10 * s).toInt().coerceAtLeast(6))
        containerView?.setPadding(pad, pad, pad, pad)
        containerView?.alpha = opacity

        // Card Background
        val bg = GradientDrawable().apply {
            setColor(cardBgColor)
            cornerRadius = dp2px((16 * s).toInt().coerceAtLeast(8)).toFloat()
            setStroke(dp2px(1.5f * s), primaryColor)
        }
        containerView?.background = bg

        // Dot View
        val dotBg = GradientDrawable().apply {
            setColor(primaryColor)
            shape = GradientDrawable.OVAL
        }
        dotView?.background = dotBg

        // Text Colors & Real-Time Font Sizes
        titleTv?.apply {
            setTextColor(subTextColor)
            textSize = 11f * s
        }

        minBtn?.apply {
            setTextColor(subTextColor)
            textSize = 13f * s
        }

        expandBtn?.apply {
            setTextColor(subTextColor)
            textSize = 13f * s
        }

        fullTimeTv?.apply {
            setTextColor(textColor)
            textSize = 22f * s
            setPadding(0, dp2px(4 * s), 0, dp2px(2 * s))
        }

        miniTimeTv?.apply {
            setTextColor(textColor)
            textSize = 14f * s
            setPadding(dp2px(4 * s), 0, dp2px(8 * s), 0)
        }

        miniIconTv?.apply {
            setTextColor(primaryColor)
            textSize = 13f * s
        }

        subTextView?.apply {
            setTextColor(subTextColor)
            textSize = 9f * s
            setPadding(dp2px(6 * s), 0, 0, 0)
        }

        // Source Badge Background, Padding & Color
        val badgeBg = GradientDrawable().apply {
            val alphaPrimary = Color.argb(
                40,
                Color.red(primaryColor),
                Color.green(primaryColor),
                Color.blue(primaryColor)
            )
            setColor(alphaPrimary)
            cornerRadius = dp2px((4 * s).toInt().coerceAtLeast(2)).toFloat()
        }
        sourceBadgeTv?.apply {
            background = badgeBg
            setTextColor(primaryColor)
            textSize = 9f * s
            val padH = dp2px(4 * s)
            val padV = dp2px(2 * s)
            setPadding(padH, padV, padH, padV)
        }
    }

    private fun dp2px(dp: Number): Int {
        val density = resources.displayMetrics.density
        return (dp.toFloat() * density + 0.5f).toInt()
    }

    override fun onDestroy() {
        super.onDestroy()
        isRunning = false
        instance = null
        runnable?.let { handler?.removeCallbacks(it) }
        if (containerView != null && windowManager != null) {
            try {
                windowManager?.removeView(containerView)
            } catch (_: Exception) {}
        }
    }
}
