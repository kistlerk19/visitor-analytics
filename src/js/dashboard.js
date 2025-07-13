document.addEventListener('DOMContentLoaded', function() {
    // Auto-refresh functionality
    let refreshInterval;
    
    function startAutoRefresh() {
        refreshInterval = setInterval(() => {
            refreshDashboard();
        }, 30000); // Refresh every 30 seconds
    }
    
    function stopAutoRefresh() {
        if (refreshInterval) {
            clearInterval(refreshInterval);
        }
    }
    
    function refreshDashboard() {
        // Add loading indicator
        const statsCards = document.querySelectorAll('.stat-number');
        statsCards.forEach(card => {
            card.innerHTML = '<div class="loading"></div>';
        });
        
        // Reload page to get fresh data
        window.location.reload();
    }
    
    // Add refresh button
    const header = document.querySelector('header');
    const refreshButton = document.createElement('button');
    refreshButton.innerHTML = '🔄 Refresh';
    refreshButton.style.cssText = `
        background: rgba(255,255,255,0.2);
        border: 1px solid rgba(255,255,255,0.3);
        color: white;
        padding: 10px 20px;
        border-radius: 25px;
        cursor: pointer;
        margin-top: 15px;
        font-size: 14px;
        transition: all 0.3s ease;
    `;
    
    refreshButton.addEventListener('mouseenter', function() {
        this.style.background = 'rgba(255,255,255,0.3)';
    });
    
    refreshButton.addEventListener('mouseleave', function() {
        this.style.background = 'rgba(255,255,255,0.2)';
    });
    
    refreshButton.addEventListener('click', refreshDashboard);
    header.appendChild(refreshButton);
    
    // Add auto-refresh toggle
    const autoRefreshToggle = document.createElement('label');
    autoRefreshToggle.innerHTML = `
        <input type="checkbox" id="autoRefresh" checked> Auto-refresh (30s)
    `;
    autoRefreshToggle.style.cssText = `
        color: white;
        margin-left: 15px;
        font-size: 14px;
        cursor: pointer;
    `;
    
    const checkbox = autoRefreshToggle.querySelector('input');
    checkbox.addEventListener('change', function() {
        if (this.checked) {
            startAutoRefresh();
        } else {
            stopAutoRefresh();
        }
    });
    
    header.appendChild(autoRefreshToggle);
    
    // Start auto-refresh by default
    startAutoRefresh();
    
    // Add real-time clock
    const clock = document.createElement('div');
    clock.style.cssText = `
        position: fixed;
        top: 20px;
        right: 20px;
        background: rgba(0,0,0,0.7);
        color: white;
        padding: 10px 15px;
        border-radius: 20px;
        font-family: monospace;
        font-size: 14px;
        z-index: 1000;
    `;
    
    function updateClock() {
        const now = new Date();
        clock.textContent = now.toLocaleString();
    }
    
    updateClock();
    setInterval(updateClock, 1000);
    document.body.appendChild(clock);
    
    // Add country flag emojis (basic mapping)
    const countryFlags = {
        'United States': '🇺🇸',
        'Canada': '🇨🇦',
        'United Kingdom': '🇬🇧',
        'Germany': '🇩🇪',
        'France': '🇫🇷',
        'Japan': '🇯🇵',
        'China': '🇨🇳',
        'India': '🇮🇳',
        'Brazil': '🇧🇷',
        'Australia': '🇦🇺',
        'Netherlands': '🇳🇱',
        'Sweden': '🇸🇪',
        'Norway': '🇳🇴',
        'Denmark': '🇩🇰',
        'Finland': '🇫🇮',
        'Spain': '🇪🇸',
        'Italy': '🇮🇹',
        'Russia': '🇷🇺',
        'South Korea': '🇰🇷',
        'Mexico': '🇲🇽'
    };
    
    // Add flags to country cells
    const countryCells = document.querySelectorAll('td');
    countryCells.forEach(cell => {
        const text = cell.textContent.trim();
        const parts = text.split(', ');
        if (parts.length >= 2) {
            const country = parts[1];
            const flag = countryFlags[country];
            if (flag) {
                cell.innerHTML = `${flag} ${text}`;
            }
        }
    });
    
    // Add browser icons
    const browserIcons = {
        'Chrome': '🌐',
        'Firefox': '🦊',
        'Safari': '🧭',
        'Edge': '🔷',
        'Opera': '🎭'
    };
    
    // Add icons to browser cells
    const browserCells = document.querySelectorAll('td:nth-child(3)');
    browserCells.forEach(cell => {
        const text = cell.textContent.trim();
        const browserName = text.split(' ')[0];
        const icon = browserIcons[browserName];
        if (icon) {
            cell.innerHTML = `${icon} ${text}`;
        }
    });
    
    // Add device type icons
    const deviceIcons = {
        'Desktop': '🖥️',
        'Mobile': '📱',
        'Tablet': '📱'
    };
    
    // Add icons to device cells
    const deviceCells = document.querySelectorAll('td:nth-child(5)');
    deviceCells.forEach(cell => {
        const text = cell.textContent.trim();
        const icon = deviceIcons[text];
        if (icon) {
            cell.innerHTML = `${icon} ${text}`;
        }
    });
});