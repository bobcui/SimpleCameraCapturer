document.addEventListener('DOMContentLoaded', function() {
    // Add smooth scrolling for anchor links
    document.querySelectorAll('a[href^="#"]').forEach(anchor => {
        anchor.addEventListener('click', function(e) {
            e.preventDefault();
            
            const targetId = this.getAttribute('href');
            const targetElement = document.querySelector(targetId);
            
            if (targetElement) {
                window.scrollTo({
                    top: targetElement.offsetTop - 50,
                    behavior: 'smooth'
                });
            }
        });
    });
    
    // Add download tracking
    const downloadButton = document.querySelector('.download-btn');
    if (downloadButton) {
        downloadButton.addEventListener('click', function() {
            console.log('SimpleCapture download initiated');
            // Here you could add analytics tracking if needed in the future
        });
    }
    
    // Add nice hover effects to feature items
    const featureItems = document.querySelectorAll('.features li');
    featureItems.forEach(item => {
        item.addEventListener('mouseenter', function() {
            this.style.transform = 'translateX(5px)';
            this.style.transition = 'transform 0.2s ease';
        });
        
        item.addEventListener('mouseleave', function() {
            this.style.transform = 'translateX(0)';
        });
    });
    
    // Check if the ZIP file exists and update download button state
    fetch('SimpleCapture.zip', { method: 'HEAD' })
        .then(response => {
            if (!response.ok) {
                const downloadBtn = document.querySelector('.download-btn');
                if (downloadBtn) {
                    downloadBtn.textContent = 'Download Unavailable';
                    downloadBtn.classList.add('disabled');
                    downloadBtn.style.backgroundColor = '#999';
                    downloadBtn.style.cursor = 'not-allowed';
                    downloadBtn.href = '#';
                    downloadBtn.addEventListener('click', e => e.preventDefault());
                }
            }
        })
        .catch(error => {
            console.error('Error checking download availability:', error);
        });
});