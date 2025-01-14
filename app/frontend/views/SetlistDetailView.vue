<script setup>
import DataSource from '@/DataSource'
import client from '@/client'
import SongsheetItem from '@/components/SongsheetItem.vue'
import AddToLibraryButton from '../components/AddToLibraryButton.vue'
import ShareItem from '@/components/ShareItem.vue'
import { toastController, actionSheetController } from '@ionic/vue'
import * as icons from '@/icons'
import { ref, defineProps, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'

const props = defineProps({
  id: {
    type: String,
    required: true
  }
})

const route = useRoute()
const router = useRouter()
const dataSource = ref(new DataSource(`setlists/${props.id}/items.json`, { params: route.query }))
const editing = ref(false)
const setlist = ref({})

onMounted(() => {
  client.get(`setlists/${props.id}.json`).then(response => {
    setlist.value = response.data
  })

  dataSource.value.load()
})

async function reorder (e) {
  const songsheet = dataSource.value.items[e.detail.from]

  await client.patch(`setlists/${props.id}/items/${songsheet.id}.json`, {
    item: { position: e.detail.to + 1 }
  })

  e.detail.complete(true)
}

async function remove (songsheet) {
  await client.delete(`setlists/${props.id}/items/${songsheet.id}.json`)
  dataSource.value.items.splice(dataSource.value.items.indexOf(songsheet), 1)
  return (await toastController.create({
    message: `${songsheet.title} was removed from ${setlist.value.title}`,
    duration: 3000
  })).present()
}

async function destroy () {
  const actionSheet = await actionSheetController
    .create({
      header: 'Are you sure you want to delete this setlist?',
      buttons: [
        {
          text: 'Delete setlist',
          role: 'destructive',
          icon: icons.trash,
          handler: async () => {
            await client.delete(`setlists/${props.id}.json`)
            router.back({ name: 'setlists' })
          }
        },
        { text: 'Cancel', icon: close, role: 'cancel' }
      ]
    })
  await actionSheet.present()
}
</script>

<template>
  <ion-page>
    <ion-header
      translucent
      collapse="fade"
    >
      <ion-toolbar>
        <ion-title>{{ setlist.title }}</ion-title>

        <ion-buttons slot="start">
          <ion-back-button
            text="Setlists"
            :default-href="{ name: 'setlists' }"
          />
        </ion-buttons>

        <ion-buttons slot="end">
          <ion-button
            v-show="editing"
            @click="editing = false"
          >
            Done
          </ion-button>
          <add-to-library-button
            v-if="setlist.id && !editing"
            :id="setlist.id"
          />
          <ion-button
            v-if="!editing"
            :id="`setlist-context-${setlist.id}`"
          >
            <ion-icon
              slot="icon-only"
              size="small"
              :ios="icons.iosEllipsis"
              :md="icons.mdEllipsis"
            />
          </ion-button>
        </ion-buttons>
      </ion-toolbar>
    </ion-header>

    <ion-content fullscreen>
      <ion-header collapse="condense">
        <ion-toolbar>
          <ion-title>{{ setlist.title }}</ion-title>
        </ion-toolbar>
      </ion-header>

      <p class="ion-padding">
        {{ setlist.description }}
      </p>

      <ion-list>
        <ion-reorder-group
          :disabled="!editing"
          @ion-item-reorder="reorder"
        >
          <ion-item-sliding
            v-for="songsheet in dataSource.items"
            :key="songsheet.id"
          >
            <ion-item-options side="end">
              <ion-item-option
                color="danger"
                @click="remove(songsheet)"
              >
                Remove
              </ion-item-option>
            </ion-item-options>

            <songsheet-item
              :songsheet="songsheet"
            >
              <!-- <ion-reorder slot="end"></ion-reorder> -->
            </songsheet-item>
          </ion-item-sliding>
        </ion-reorder-group>
      </ion-list>

      <ion-infinite-scroll
        threshold="500px"
        :disabled="dataSource.loading || dataSource.disabled"
        @ion-infinite="dataSource.load().then(() => $event.target.complete())"
      >
        <ion-infinite-scroll-content
          loading-spinner="bubbles"
          loading-text="Loading…"
        />
      </ion-infinite-scroll>
    </ion-content>

    <ion-popover
      :trigger="`setlist-context-${setlist.id}`"
      dismiss-on-select
    >
      <ion-list>
        <ion-item
          button
          detail
          :detail-icon="icons.edit"
          @click="editing = true"
        >
          <ion-label>Edit</ion-label>
        </ion-item>
        <ion-item
          button
          detail
          :detail-icon="icons.trash"
          @click="destroy"
        >
          <ion-label>Delete</ion-label>
        </ion-item>
        <share-item
          lines="none"
          :title="setlist.title"
          :router-link="{ name: 'setlist', params: { id } }"
        />
      </ion-list>
    </ion-popover>
  </ion-page>
</template>
