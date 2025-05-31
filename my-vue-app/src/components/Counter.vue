<script>
import { ref } from 'vue'

export default {
  name: 'Counter',
  props: {
    initialCount: {
      type: Number,
      default: 0
    }
  },
  setup(props) {
    const count = ref(props.initialCount);
    const increment = () => {
      count.value++;
    };
    return { count, increment };
  }
};
</script>

<template>
  <div>
    <button @click="increment">Count is: {{ count }}</button>
  </div>
</template>
