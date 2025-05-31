<script>
import { ref } from 'vue'
import Counter from './Counter.vue'

export default {
  name: 'Sample',
  props: {
    name: {
      type: String,
      default: 'defaultName'
    }
  },
  setup() {
    const items = ref([1, 2, 3]);
    const addItem = () => {
      items.value.push(items.value.length + 1);
    };
    return { items, addItem }
  },
  components: {
    Counter
  }
};
</script>

<template>
  <div>
    <h2>{{ name }}</h2>
    <ul>
      <li v-for="item in items" :key="item">
        <Counter />
      </li>
    </ul>
  </div>
</template>
