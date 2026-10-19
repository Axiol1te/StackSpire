package com.follow.clash

import android.annotation.SuppressLint
import android.os.Build
import android.graphics.drawable.Icon
import android.service.quicksettings.Tile
import com.follow.clash.common.QuickAction
import com.follow.clash.common.quickIntent
import com.follow.clash.common.toPendingIntent
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch

class TileService : android.service.quicksettings.TileService() {
    private var scope: CoroutineScope? = null

    override fun onStartListening() {
        super.onStartListening()
        scope?.cancel()
        scope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate).also { scope ->
            scope.launch {
                ServiceState.runState.collect(::updateTile)
            }
        }
    }

    override fun onClick() {
        super.onClick()
        if (!ServiceState.isRunRequested &&
            android.net.VpnService.prepare(this) != null
        ) {
            openQuickAction()
            return
        }
        com.follow.clash.common.GlobalState.launch {
            ServiceState.handleToggleAction()
        }
    }

    override fun onStopListening() {
        scope?.cancel()
        scope = null
        super.onStopListening()
    }

    private fun updateTile(runState: RunState) {
        qsTile?.apply {
            icon = Icon.createWithResource(this@TileService, R.drawable.ic_stackspire_tile)
            state = when (runState) {
                RunState.STARTED, RunState.STARTING -> Tile.STATE_ACTIVE
                RunState.STOPPED, RunState.STOPPING -> Tile.STATE_INACTIVE
            }
            updateTile()
        }
    }

    @SuppressLint("StartActivityAndCollapseDeprecated")
    private fun openQuickAction() {
        val intent = QuickAction.TOGGLE.quickIntent
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            startActivityAndCollapse(intent.toPendingIntent)
        } else {
            @Suppress("DEPRECATION")
            startActivityAndCollapse(intent)
        }
    }
}
