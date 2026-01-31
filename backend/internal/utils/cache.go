package utils

import (
	"sync"
	"time"
)

// CacheItem represents a single cached value
type CacheItem struct {
	Value      interface{}
	Expiration time.Time
}

// MemoryCache is a simple in-memory key-value store with TTL
type MemoryCache struct {
	items map[string]CacheItem
	mutex sync.RWMutex
}

var GlobalCache *MemoryCache

func init() {
	GlobalCache = NewMemoryCache()
}

// NewMemoryCache creates a new cache instance
func NewMemoryCache() *MemoryCache {
	return &MemoryCache{
		items: make(map[string]CacheItem),
	}
}

// Set adds an item to the cache
func (c *MemoryCache) Set(key string, value interface{}, duration time.Duration) {
	c.mutex.Lock()
	defer c.mutex.Unlock()

	c.items[key] = CacheItem{
		Value:      value,
		Expiration: time.Now().Add(duration),
	}
}

// Get retrieves an item from the cache
func (c *MemoryCache) Get(key string) (interface{}, bool) {
	c.mutex.RLock()
	defer c.mutex.RUnlock()

	item, found := c.items[key]
	if !found {
		return nil, false
	}

	if time.Now().After(item.Expiration) {
		return nil, false
	}

	return item.Value, true
}

// Delete removes an item from the cache
func (c *MemoryCache) Delete(key string) {
	c.mutex.Lock()
	defer c.mutex.Unlock()
	delete(c.items, key)
}
