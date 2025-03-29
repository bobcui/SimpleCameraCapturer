// SimpleCapture Landing Page JavaScript

document.addEventListener('DOMContentLoaded', function() {
    // Smooth scrolling for anchor links
    document.querySelectorAll('a[href^="#"]').forEach(anchor => {
        anchor.addEventListener('click', function(e) {
            e.preventDefault();
            
            const targetId = this.getAttribute('href').substring(1);
            if (!targetId) return;
            
            const targetElement = document.getElementById(targetId);
            if (targetElement) {
                window.scrollTo({
                    top: targetElement.offsetTop - 70,
                    behavior: 'smooth'
                });
            }
        });
    });
    
    // Download tracking
    const downloadButtons = document.querySelectorAll('.download-btn');
    downloadButtons.forEach(button => {
        button.addEventListener('click', function() {
            console.log('SimpleCapture download initiated');
            // Could add analytics tracking here
        });
    });
    
    // Check if zip file exists to enable/disable download buttons
    checkFileExists('SimpleCapture.zip')
        .then(exists => {
            if (!exists) {
                const downloadButtons = document.querySelectorAll('.download-btn');
                downloadButtons.forEach(button => {
                    button.classList.add('disabled');
                    button.textContent = 'Download Coming Soon';
                    button.addEventListener('click', function(e) {
                        e.preventDefault();
                        alert('The SimpleCapture package is still being prepared. Please check back soon!');
                    });
                });
            }
        });
});

// Helper function to check if a file exists
function checkFileExists(url) {
    return new Promise(resolve => {
        const xhr = new XMLHttpRequest();
        xhr.open('HEAD', url, true);
        xhr.onreadystatechange = function() {
            if (xhr.readyState === 4) {
                resolve(xhr.status !== 404);
            }
        };
        xhr.send();
    });
}