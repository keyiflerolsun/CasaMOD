// author: keyiflerolsun
// date: 2025-11-02

(function () {
    const observedAnchor = '.ps-container';
    function moduleFunction() {
        // div class="widget has-text-white clock is-relative mt-4" olan elementi sil
        const clockWidget = document.querySelector('.widget.has-text-white.clock.is-relative.mt-4');
        if (clockWidget) {
            clockWidget.remove();
        }
        const scrollArea = document.querySelector('.scroll-area');
        scrollArea.style.maxHeight = 'calc(100% - 2.5rem)';
    }

    // ================================================
    // Observe and wait for Vue rendering to complete.
    // ================================================
    const observer = new MutationObserver(mutations => {
        mutations.forEach(mutation => {
            if (mutation.target.querySelector(observedAnchor)) {
                observer.disconnect();
                debounced();
            }
        });
    });
    observer.observe(document.body, { childList: true, subtree: true, once: true });
    function debounce(func, wait) {
        let timeout;
        return (...args) => {
            clearTimeout(timeout);
            timeout = setTimeout(() => func.apply(this, args), wait);
        };
    }
    const debounced = debounce(moduleFunction, 1);
})();
