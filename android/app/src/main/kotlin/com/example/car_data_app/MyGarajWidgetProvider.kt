package com.example.car_data_app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class MyGarajWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.my_garaj_widget).apply {
                val title = widgetData.getString("title", "Yaklaşanlar") ?: "Yaklaşanlar"
                val empty = widgetData.getBoolean("empty", true)
                val line1 = widgetData.getString("line1", "") ?: ""
                val line2 = widgetData.getString("line2", "") ?: ""
                val line3 = widgetData.getString("line3", "") ?: ""

                setTextViewText(R.id.widget_title, title)
                setTextViewText(R.id.widget_line1, line1)
                setViewVisibility(
                    R.id.widget_line1,
                    if (line1.isNotEmpty()) View.VISIBLE else View.GONE
                )
                setTextViewText(R.id.widget_line2, line2)
                setViewVisibility(
                    R.id.widget_line2,
                    if (!empty && line2.isNotEmpty()) View.VISIBLE else View.GONE
                )
                setTextViewText(R.id.widget_line3, line3)
                setViewVisibility(
                    R.id.widget_line3,
                    if (!empty && line3.isNotEmpty()) View.VISIBLE else View.GONE
                )
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
