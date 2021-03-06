export default {
  template: require('./app_builds.html'),
  components: {
    navbar: require('components/navbar').default,
    appmenu: require('components/appmenu').default
  },
  methods: {
    show(ev) {
      this.$router.push(ev.target.parentNode.dataset.href);
    }
  }
};
