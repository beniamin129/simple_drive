// Simple Drive Dashboard JavaScript

let authToken = null;
let currentStorage = 'all'; // Current storage filter
let currentPage = 1; // Current page number
let paginationInfo = null; // Pagination metadata
const API_BASE_URL = '/v1';

// Initialize on page load
document.addEventListener('DOMContentLoaded', function() {
    updateAuthButton();
    refreshBlobs();
});

// Authentication
function updateAuthButton() {
    const btn = document.getElementById('authBtn');
    if (authToken) {
        btn.textContent = 'Logged In';
        btn.className = 'px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 transition';
        btn.onclick = logout;
    } else {
        btn.textContent = 'Login';
        btn.className = 'px-4 py-2 bg-primary text-white rounded-lg hover:bg-blue-600 transition';
        btn.onclick = login;
    }
}

async function login() {
    try {
        const response = await fetch(`${API_BASE_URL}/auth/tokens`, {
            method: 'POST'
        });
        
        if (response.ok) {
            const data = await response.json();
            authToken = data.token;
            localStorage.setItem('authToken', authToken);
            updateAuthButton();
            showNotification('Login successful!', 'success');
        } else {
            showNotification('Login failed', 'error');
        }
    } catch (error) {
        showNotification('Error: ' + error.message, 'error');
    }
}

function logout() {
    authToken = null;
    localStorage.removeItem('authToken');
    updateAuthButton();
    showNotification('Logged out', 'info');
    refreshBlobs();
}

// Load token from localStorage on page load
window.addEventListener('load', function() {
    const savedToken = localStorage.getItem('authToken');
    if (savedToken) {
        authToken = savedToken;
        updateAuthButton();
    }
});

// Blob Operations
async function createBlob() {
    const blobId = document.getElementById('blobId').value.trim();
    const blobData = document.getElementById('blobData').value.trim();
    const storageBackend = document.getElementById('createStorageBackend').value;
    
    if (!blobId || !blobData) {
        showNotification('Please fill in both ID and Data fields', 'error');
        return;
    }
    
    if (!authToken) {
        showNotification('Please login first', 'error');
        return;
    }
    
    try {
        // Convert data to Base64
        const base64Data = btoa(blobData);
        
        const response = await fetch(`${API_BASE_URL}/blobs?storage_backend=${storageBackend}`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${authToken}`
            },
            body: JSON.stringify({
                id: blobId,
                data: base64Data
            })
        });
        
        if (response.ok) {
            const data = await response.json();
            showNotification(`Blob "${blobId}" created successfully!`, 'success');
            document.getElementById('blobId').value = '';
            document.getElementById('blobData').value = '';
            // Auto-refresh to show the new blob immediately
            await refreshBlobs();
        } else {
            const error = await response.json();
            showNotification(`Failed to create blob: ${error.error}`, 'error');
        }
    } catch (error) {
        showNotification('Error: ' + error.message, 'error');
    }
}

async function refreshBlobs(page = currentPage) {
    if (!authToken) {
        document.getElementById('blobsList').innerHTML = `
            <tr>
                <td colspan="5" class="px-6 py-4 text-center text-gray-500">
                    Please login to view blobs
                </td>
            </tr>
        `;
        return;
    }
    
    try {
        const response = await fetch(`${API_BASE_URL}/blobs?page=${page}&per_page=20`, {
            headers: {
                'Authorization': `Bearer ${authToken}`
            }
        });
        
        if (response.ok) {
            const responseData = await response.json();
            const allBlobs = responseData.data || [];
            
            // Store pagination info
            paginationInfo = responseData.pagination || { page: 1, total_pages: 1 };
            currentPage = paginationInfo.page;
            
            // Get current backend info
            await updateCurrentBackend();
            
            // Filter blobs based on current storage selection
            const filteredBlobs = filterBlobsByStorage(allBlobs);
            displayBlobs(filteredBlobs);
            
            // Update pagination controls
            updatePaginationControls();
            
            // Update stats with total count from pagination
            document.getElementById('totalBlobs').textContent = paginationInfo.total_count || filteredBlobs.length;
            
            const totalSize = filteredBlobs.reduce((sum, blob) => sum + parseInt(blob.size), 0);
            document.getElementById('totalSize').textContent = formatBytes(totalSize);
        } else {
            document.getElementById('blobsList').innerHTML = `
                <tr>
                    <td colspan="5" class="px-6 py-4 text-center text-gray-500">
                        Failed to load blobs
                    </td>
                </tr>
            `;
        }
    } catch (error) {
        showNotification('Error: ' + error.message, 'error');
        document.getElementById('blobsList').innerHTML = `
            <tr>
                <td colspan="5" class="px-6 py-4 text-center text-red-500">
                    Error loading blobs: ${error.message}
                </td>
            </tr>
        `;
    }
}

function displayBlobs(blobs) {
    const tbody = document.getElementById('blobsList');
    
    if (!blobs || blobs.length === 0) {
        tbody.innerHTML = `
            <tr>
                <td colspan="5" class="px-6 py-4 text-center text-gray-500">
                    No blobs found. Create your first blob above!
                </td>
            </tr>
        `;
        return;
    }
    
    tbody.innerHTML = blobs.map(blob => `
        <tr class="hover:bg-gray-50">
            <td class="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">
                ${blob.id}
            </td>
            <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                <span class="px-2 py-1 bg-blue-100 text-blue-800 rounded-full text-xs font-medium">
                    ${blob.storage || 'unknown'}
                </span>
            </td>
            <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                ${formatBytes(parseInt(blob.size))}
            </td>
            <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                ${new Date(blob.created_at).toLocaleString()}
            </td>
            <td class="px-6 py-4 whitespace-nowrap text-sm font-medium space-x-2">
                <button onclick="getBlob('${blob.id}')" class="text-blue-600 hover:text-blue-900">View</button>
                <button onclick="deleteBlob('${blob.id}')" class="text-red-600 hover:text-red-900">Delete</button>
            </td>
        </tr>
    `).join('');
}

function formatBytes(bytes) {
    if (bytes === 0) return '0 B';
    const k = 1024;
    const sizes = ['B', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return Math.round(bytes / Math.pow(k, i) * 100) / 100 + ' ' + sizes[i];
}

async function getBlob(id) {
    if (!authToken) {
        showNotification('Please login first', 'error');
        return;
    }
    
    try {
        const response = await fetch(`${API_BASE_URL}/blobs/${id}`, {
            headers: {
                'Authorization': `Bearer ${authToken}`
            }
        });
        
        if (response.ok) {
            const data = await response.json();
            showBlobDetails(data);
        } else {
            showNotification('Failed to retrieve blob', 'error');
        }
    } catch (error) {
        showNotification('Error: ' + error.message, 'error');
    }
}

async function deleteBlob(id) {
    if (!authToken) {
        showNotification('Please login first', 'error');
        return;
    }
    
    if (!confirm(`Are you sure you want to delete blob "${id}"?`)) {
        return;
    }
    
    try {
        const response = await fetch(`${API_BASE_URL}/blobs/${id}`, {
            method: 'DELETE',
            headers: {
                'Authorization': `Bearer ${authToken}`
            }
        });
        
        if (response.ok) {
            showNotification(`Blob "${id}" deleted successfully`, 'success');
            refreshBlobs();
        } else {
            showNotification('Failed to delete blob', 'error');
        }
    } catch (error) {
        showNotification('Error: ' + error.message, 'error');
    }
}

function showBlobDetails(blob) {
    const modal = document.getElementById('modal');
    const content = document.getElementById('modalContent');
    
    try {
        const decodedData = atob(blob.data);
        
        content.innerHTML = `
            <div class="space-y-4">
                <div>
                    <label class="text-sm font-medium text-gray-500">ID</label>
                    <p class="mt-1 text-gray-900">${blob.id}</p>
                </div>
                <div>
                    <label class="text-sm font-medium text-gray-500">Size</label>
                    <p class="mt-1 text-gray-900">${blob.size} bytes</p>
                </div>
                <div>
                    <label class="text-sm font-medium text-gray-500">Created At</label>
                    <p class="mt-1 text-gray-900">${blob.created_at}</p>
                </div>
                <div>
                    <label class="text-sm font-medium text-gray-500">Data (Base64)</label>
                    <textarea readonly class="mt-1 w-full px-3 py-2 border border-gray-300 rounded-md bg-gray-50" rows="3">${blob.data}</textarea>
                </div>
                <div>
                    <label class="text-sm font-medium text-gray-500">Data (Decoded)</label>
                    <textarea readonly class="mt-1 w-full px-3 py-2 border border-gray-300 rounded-md bg-gray-50" rows="3">${decodedData}</textarea>
                </div>
            </div>
        `;
        
        modal.classList.remove('hidden');
    } catch (error) {
        content.innerHTML = `
            <div class="text-red-600">
                <p>Error displaying blob data: ${error.message}</p>
            </div>
        `;
        modal.classList.remove('hidden');
    }
}

function closeModal() {
    const modal = document.getElementById('modal');
    modal.classList.add('hidden');
}

// Notification system
function showNotification(message, type = 'info') {
    const colors = {
        success: 'bg-green-500',
        error: 'bg-red-500',
        info: 'bg-blue-500'
    };
    
    const notification = document.createElement('div');
    notification.className = `fixed top-4 right-4 px-6 py-3 text-white rounded-lg shadow-lg z-50 ${colors[type] || colors.info}`;
    notification.textContent = message;
    
    document.body.appendChild(notification);
    
    setTimeout(() => {
        notification.style.opacity = '0';
        notification.style.transition = 'opacity 0.3s';
        setTimeout(() => {
            document.body.removeChild(notification);
        }, 300);
    }, 3000);
}

// Update storage backend info
async function updateStorageInfo() {
    const backend = localStorage.getItem('storageBackend') || 'local';
    document.getElementById('storageBackend').textContent = backend.toUpperCase();
}

// Get current active storage backend
async function updateCurrentBackend() {
    try {
        const response = await fetch(`${API_BASE_URL}/storage/backend`, {
            headers: authToken ? { 'Authorization': `Bearer ${authToken}` } : {}
        });
        
        if (response.ok) {
            const data = await response.json();
            const backend = data.backend || 'local';
            document.getElementById('storageBackend').textContent = backend.toUpperCase();
            
            // Store for later use
            localStorage.setItem('storageBackend', backend);
        } else {
            // Fallback to config value
            const backend = Rails?.application?.config?.storage_backend || 'local';
            document.getElementById('storageBackend').textContent = backend.toUpperCase();
        }
    } catch (error) {
        // Silent fallback
        const backend = localStorage.getItem('storageBackend') || 'local';
        document.getElementById('storageBackend').textContent = backend.toUpperCase();
    }
}

// Handle storage filter change
function handleStorageChange() {
    currentStorage = document.getElementById('storageFilter').value;
    refreshBlobs();
}

// Filter blobs by storage type
function filterBlobsByStorage(blobs) {
    if (currentStorage === 'all') {
        return blobs;
    }
    return blobs.filter(blob => blob.storage === currentStorage);
}

// Pagination functions
function updatePaginationControls() {
    // Remove existing pagination controls if any
    const existingControls = document.getElementById('paginationControls');
    if (existingControls) {
        existingControls.remove();
    }
    
    if (!paginationInfo || paginationInfo.total_pages <= 1) {
        return;
    }
    
    const tableParent = document.querySelector('.bg-white.rounded-lg.shadow.overflow-hidden');
    const paginationHTML = `
        <div id="paginationControls" class="px-6 py-4 border-t border-gray-200 flex items-center justify-between">
            <div class="flex-1 flex justify-between sm:hidden">
                <button 
                    onclick="goToPage(${currentPage - 1})" 
                    ${!paginationInfo.has_prev ? 'disabled' : ''}
                    class="px-4 py-2 ${paginationInfo.has_prev ? 'bg-white border border-gray-300 rounded-lg hover:bg-gray-50' : 'bg-gray-100 cursor-not-allowed'} text-sm font-medium text-gray-700"
                >
                    Previous
                </button>
                <button 
                    onclick="goToPage(${currentPage + 1})" 
                    ${!paginationInfo.has_next ? 'disabled' : ''}
                    class="px-4 py-2 ${paginationInfo.has_next ? 'bg-white border border-gray-300 rounded-lg hover:bg-gray-50' : 'bg-gray-100 cursor-not-allowed'} text-sm font-medium text-gray-700"
                >
                    Next
                </button>
            </div>
            <div class="hidden sm:flex-1 sm:flex sm:items-center sm:justify-between">
                <div>
                    <p class="text-sm text-gray-700">
                        Showing <span class="font-medium">${(currentPage - 1) * 20 + 1}</span> to 
                        <span class="font-medium">${Math.min(currentPage * 20, paginationInfo.total_count)}</span> of 
                        <span class="font-medium">${paginationInfo.total_count}</span> results
                    </p>
                </div>
                <div>
                    <nav class="relative z-0 inline-flex rounded-md shadow-sm -space-x-px" aria-label="Pagination">
                        <button 
                            onclick="goToPage(${currentPage - 1})" 
                            ${!paginationInfo.has_prev ? 'disabled' : ''}
                            class="relative inline-flex items-center px-2 py-2 rounded-l-md border ${paginationInfo.has_prev ? 'border-gray-300 bg-white hover:bg-gray-50' : 'border-gray-200 bg-gray-50 cursor-not-allowed'} text-sm font-medium text-gray-500"
                        >
                            Previous
                        </button>
                        <span class="relative inline-flex items-center px-4 py-2 border border-gray-300 bg-white text-sm font-medium text-gray-700">
                            Page ${currentPage} of ${paginationInfo.total_pages}
                        </span>
                        <button 
                            onclick="goToPage(${currentPage + 1})" 
                            ${!paginationInfo.has_next ? 'disabled' : ''}
                            class="relative inline-flex items-center px-2 py-2 rounded-r-md border ${paginationInfo.has_next ? 'border-gray-300 bg-white hover:bg-gray-50' : 'border-gray-200 bg-gray-50 cursor-not-allowed'} text-sm font-medium text-gray-500"
                        >
                            Next
                        </button>
                    </nav>
                </div>
            </div>
        </div>
    `;
    
    tableParent.insertAdjacentHTML('beforeend', paginationHTML);
}

function goToPage(page) {
    if (page < 1 || (paginationInfo && page > paginationInfo.total_pages)) {
        return;
    }
    
    currentPage = page;
    refreshBlobs(page);
}

// Call updateStorageInfo on load
updateStorageInfo();

