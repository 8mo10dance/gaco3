<script>
import { ref, computed, watch } from 'vue'

export default {
  name: 'Sample',
  setup() {
    const count = ref(0);
    const increment = () => {
      count.value++;
    };
    watch(count, (newVal, oldVal) => {
      console.log(`Count changed from ${oldVal} to ${newVal}`);
    });
    const doubleCount = computed(() => count.value * 2);
    return { items: [1,2,3], count, doubleCount, increment };
  }
};
</script>

<template>
  <div>
    <h1>Sample Component</h1>
    <ul>
      <li v-for="item in items" :key="item">
        {{ item }}
      </li>
    </ul>
    <input type="number" v-model="count" placeholder="Type a number" />
    <button @click="increment">Count is: {{ count }}</button>
    <p>{{ doubleCount }}</p>
    <p>Edit this component to test HMR</p>
  </div>
</template>
