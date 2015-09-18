package org.fathens.ci.deploy.googleplay

import java.io.File

import scala.collection.JavaConversions._

import com.google.api.client.googleapis.auth.oauth2.GoogleCredential
import com.google.api.client.googleapis.javanet.GoogleNetHttpTransport
import com.google.api.client.http.FileContent
import com.google.api.client.json.jackson2.JacksonFactory
import com.google.api.services.androidpublisher.{ AndroidPublisher, AndroidPublisherScopes }
import com.google.api.services.androidpublisher.model.Track
import com.typesafe.scalalogging.LazyLogging

object Main extends App with LazyLogging {
  val edits = {
    val trans = GoogleNetHttpTransport.newTrustedTransport
    val jsonFactory = JacksonFactory.getDefaultInstance

    logger info f"Authorizing using Service Account: ${Settings.SERVICE_ACCOUNT_EMAIL}"
    val credential = new GoogleCredential.Builder()
      .setTransport(trans)
      .setJsonFactory(jsonFactory)
      .setServiceAccountId(Settings.SERVICE_ACCOUNT_EMAIL)
      .setServiceAccountScopes(java.util.Collections.singleton(AndroidPublisherScopes.ANDROIDPUBLISHER))
      .setServiceAccountPrivateKeyFromP12File(Settings.SERVICE_ACCOUNT_KEY)
      .build

    new AndroidPublisher.Builder(trans, jsonFactory, credential)
      .setApplicationName(Settings.APPLICATION_NAME)
      .build.edits
  }

  val editId = edits.insert(Settings.PACKAGE_NAME,
    null // no content
  ).execute.getId
  logger info f"Created edit with id: ${editId}"

  val apk = {
    val apkFile = new FileContent(Settings.MIME_TYPE_APK, Settings.APK_FILE)
    edits.apks.upload(Settings.PACKAGE_NAME, editId, apkFile).execute
  }
  logger info f"Version code ${apk.getVersionCode} has been uploaded"

  val updatedTrack = edits.tracks.update(
    Settings.PACKAGE_NAME,
    editId,
    Settings.TRACK_NAME,
    new Track().setVersionCodes(List(apk.getVersionCode))
  ).execute
  logger info f"Track ${updatedTrack.getTrack} has been updated."

  val appEdit = edits.commit(Settings.PACKAGE_NAME, editId).execute
  logger info f"App edit with id ${appEdit.getId} has been comitted"
}

object Settings {
  private def get(name: String) = System.getenv("ANDROID_GOOGLEPLAY_" + name)

  /**
   * Track for uploading the apk, can be 'alpha', beta', 'production' or 'rollout'
   */
  lazy val TRACK_NAME = get("TRACK_NAME")
  lazy val APPLICATION_NAME = get("APPLICATION_NAME")
  lazy val PACKAGE_NAME = get("PACKAGE_NAME")
  lazy val SERVICE_ACCOUNT_EMAIL = get("SERVICE_ACCOUNT_EMAIL")
  lazy val SERVICE_ACCOUNT_KEY = new File(get("SERVICE_ACCOUNT_KEY_FILE_PATH"))
  lazy val APK_FILE = new File(get("APK_FILE_PATH"))
  lazy val MIME_TYPE_APK = "application/vnd.android.package-archive"
}
