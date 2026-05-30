package expo.modules.applemusic

import com.apple.android.music.playback.model.MediaPlayerException
import expo.modules.applemusic.bridge.registerAuthBridge
import expo.modules.applemusic.bridge.registerCatalogBridge
import expo.modules.applemusic.bridge.registerHistoryBridge
import expo.modules.applemusic.bridge.registerLibraryBridge
import expo.modules.applemusic.bridge.registerLibraryMutationsBridge
import expo.modules.applemusic.bridge.registerPlayerBridge
import expo.modules.applemusic.bridge.registerRatingsBridge
import expo.modules.applemusic.bridge.registerRecommendationsBridge
import expo.modules.kotlin.exception.CodedException
import expo.modules.kotlin.activityresult.AppContextActivityResultLauncher
import expo.modules.kotlin.modules.Module
import expo.modules.kotlin.modules.ModuleDefinition
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch

class ExpoAppleMusicModule : Module() {
  private lateinit var authLauncher: AppContextActivityResultLauncher<MusicKitAuthInput, MusicKitAuthOutput>
  private var playbackObserver: AndroidPlaybackObserver? = null

  @Volatile
  private var playbackErrorHandlerWired = false

  private val moduleScope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)

  private val reactContext
    get() = requireNotNull(appContext.reactContext) { "React Application Context is null" }

  private val playbackController: AndroidPlaybackController
    get() = AndroidPlaybackController.getInstance(reactContext)

  private fun wirePlaybackErrorHandlerOnce() {
    if (playbackErrorHandlerWired) return
    AndroidPlaybackController.getInstance(reactContext).playbackErrorHandler = { error, operation ->
      emitPlaybackError(error, operation)
    }
    playbackErrorHandlerWired = true
  }

  private val catalogService: AndroidCatalogService
    get() = AndroidCatalogService(reactContext)

  private val libraryService: AndroidLibraryService
    get() = AndroidLibraryService(reactContext)

  private val historyService: AndroidHistoryService
    get() = AndroidHistoryService(reactContext)

  private val subscriptionService: AndroidSubscriptionService
    get() = AndroidSubscriptionService(reactContext)

  private val queueService: AndroidQueueService
    get() = AndroidQueueService(reactContext, playbackController)

  private val ratingsService: AndroidRatingsService
    get() = AndroidRatingsService(reactContext)

  private val libraryMutationsService: AndroidLibraryMutationsService
    get() = AndroidLibraryMutationsService(reactContext)

  private val recommendationsService: AndroidRecommendationsService
    get() = AndroidRecommendationsService(reactContext)

  override fun definition() = ModuleDefinition {
    Name("ExpoAppleMusic")

    Events(
      "onPlaybackStateChange",
      "onCurrentSongChange",
      "onPlaybackTimeUpdate",
      "onPlaybackError",
    )

    OnStartObserving {
      wirePlaybackErrorHandlerOnce()
      val observer = AndroidPlaybackObserver(reactContext)
      observer.delegate =
        object : AndroidPlaybackObserverDelegate {
          override fun onPlaybackStateChange(body: Map<String, Any?>) {
            sendEvent("onPlaybackStateChange", body)
          }

          override fun onCurrentSongChange(body: Map<String, Any?>) {
            sendEvent("onCurrentSongChange", body)
          }

          override fun onPlaybackTimeUpdate(playbackTime: Double) {
            sendEvent("onPlaybackTimeUpdate", mapOf("playbackTime" to playbackTime))
          }

          override fun onPlaybackError(body: Map<String, Any?>) {
            sendEvent("onPlaybackError", body)
          }
        }
      observer.startObserving()
      playbackObserver = observer
    }

    OnStopObserving {
      playbackObserver?.stopObserving()
      playbackObserver = null
    }

    RegisterActivityContracts {
      authLauncher =
        registerForActivityResult(
          MusicKitAuthContract {
            appContext.throwingActivity
          },
        )
      wirePlaybackErrorHandlerOnce()
    }

    registerAuthBridge(
      reactContext = { reactContext },
      authLauncher = { authLauncher },
      subscriptionService = { subscriptionService },
      libraryService = { libraryService },
    )
    registerCatalogBridge { catalogService }
    registerLibraryBridge { libraryService }
    registerHistoryBridge { historyService }
    registerPlayerBridge(
      moduleScope = moduleScope,
      playbackController = { playbackController },
      queueService = { queueService },
      emitPlaybackError = ::emitPlaybackError,
      emitPlaybackTimeUpdate = { time ->
        sendEvent("onPlaybackTimeUpdate", mapOf("playbackTime" to time))
      },
    )
    registerRatingsBridge { ratingsService }
    registerLibraryMutationsBridge { libraryMutationsService }
    registerRecommendationsBridge { recommendationsService }
  }

  private fun emitPlaybackError(error: Exception, operation: String) {
    val code =
      when (error) {
        is MediaPlayerException -> error.errorCode
        is CodedException -> error.code
        else -> 0
      }
    sendEvent(
      "onPlaybackError",
      mapOf(
        "message" to (error.message ?: "Playback error"),
        "code" to code,
        "domain" to error.javaClass.simpleName,
        "operation" to operation,
      ),
    )
  }
}
