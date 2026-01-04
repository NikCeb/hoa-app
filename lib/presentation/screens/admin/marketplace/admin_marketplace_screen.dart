import 'package:flutter/material.dart';
import '../../../../data/models/marketplace_listing.dart';
import '../../../../data/models/marketplace_category.dart';
import '../../../../data/repositories/marketplace_repository.dart';
import 'admin_marketplace_create_category_screen.dart';

class AdminMarketplaceScreen extends StatefulWidget {
  const AdminMarketplaceScreen({Key? key}) : super(key: key);

  @override
  State<AdminMarketplaceScreen> createState() => _AdminMarketplaceScreenState();
}

class _AdminMarketplaceScreenState extends State<AdminMarketplaceScreen> {
  String _activeView = 'categories'; // Default to categories
  final _repository = MarketplaceRepository();

  int _categoriesCount = 0;
  int _activeCount = 0;
  int _soldCount = 0;
  int _withdrawnCount = 0;

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  Future<void> _loadCounts() async {
    // Load listing stats
    final stats = await _repository.getListingStats();

    // Load categories count
    _repository.getAllCategories().listen((categories) {
      if (mounted) {
        setState(() {
          _categoriesCount = categories.length;
        });
      }
    });

    if (mounted) {
      setState(() {
        _activeCount = stats['active'] ?? 0;
        _soldCount = stats['sold'] ?? 0;
        _withdrawnCount = stats['withdrawn'] ?? 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF2563EB),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Marketplace Management',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          // Compact Navigation Cards (1x4 horizontal) - EDGE TO EDGE
          SizedBox(
            width: double.infinity,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF2563EB),
                    const Color(0xFF2563EB).withOpacity(0.95),
                  ],
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Center(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildNavigationCard(
                          title: 'Categories',
                          count: _categoriesCount,
                          icon: Icons.category,
                          color: Colors.purple,
                          viewKey: 'categories',
                        ),
                        const SizedBox(width: 8),
                        _buildNavigationCard(
                          title: 'Active',
                          count: _activeCount,
                          icon: Icons.storefront,
                          color: Colors.green,
                          viewKey: 'active',
                        ),
                        const SizedBox(width: 8),
                        _buildNavigationCard(
                          title: 'Sold',
                          count: _soldCount,
                          icon: Icons.check_circle,
                          color: Colors.orange,
                          viewKey: 'sold',
                        ),
                        const SizedBox(width: 8),
                        _buildNavigationCard(
                          title: 'Withdrawn',
                          count: _withdrawnCount,
                          icon: Icons.cancel,
                          color: Colors.grey,
                          viewKey: 'withdrawn',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Content
          Expanded(
            child: _activeView == 'categories'
                ? _buildCategoriesList()
                : _buildListingsList(),
          ),
        ],
      ),
      // Floating button ONLY shows when on categories tab
      floatingActionButton: _activeView == 'categories'
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const AdminMarketplaceCreateCategoryScreen(),
                  ),
                );
              },
              backgroundColor: const Color(0xFF2563EB),
              icon: const Icon(Icons.add),
              label: const Text('Add Category'),
            )
          : null,
    );
  }

  Widget _buildNavigationCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
    required String viewKey,
  }) {
    final isActive = _activeView == viewKey;

    return Card(
      elevation: isActive ? 6 : 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: isActive
            ? const BorderSide(color: Colors.white, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _activeView = viewKey;
          });
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 75,
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: isActive
                ? LinearGradient(
                    colors: [color, color.withOpacity(0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isActive ? null : color.withOpacity(0.15),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: isActive ? Colors.white : color,
              ),
              const SizedBox(height: 1),
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isActive ? Colors.white : color,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                title,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: isActive ? Colors.white : color,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CATEGORIES LIST
  // ============================================================

  Widget _buildCategoriesList() {
    return StreamBuilder<List<MarketplaceCategory>>(
      stream: _repository.getAllCategories(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
              ],
            ),
          );
        }

        final categories = snapshot.data ?? [];

        if (categories.isEmpty) {
          return _buildEmptyCategories();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            return _buildCategoryCard(categories[index]);
          },
        );
      },
    );
  }

  Widget _buildEmptyCategories() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.category, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No Categories Yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first category',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(MarketplaceCategory category) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: category.isActive
                ? const Color(0xFF2563EB).withOpacity(0.1)
                : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.category,
            color: category.isActive ? const Color(0xFF2563EB) : Colors.grey,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                category.categoryName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (!category.isActive)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'INACTIVE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            'Sort Order: ${category.sortOrder}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'edit') {
              _showEditCategoryDialog(category);
            } else if (value == 'toggle') {
              await _repository.toggleCategoryStatus(
                category.id,
                !category.isActive,
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      category.isActive
                          ? 'Category deactivated'
                          : 'Category activated',
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            } else if (value == 'delete') {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Category'),
                  content: Text(
                    'Are you sure you want to delete "${category.categoryName}"?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );

              if (confirmed == true) {
                await _repository.deleteCategory(category.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Category deleted'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  _loadCounts(); // Refresh counts
                }
              }
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 12),
                  Text('Edit'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'toggle',
              child: Row(
                children: [
                  Icon(
                    category.isActive ? Icons.visibility_off : Icons.visibility,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(category.isActive ? 'Deactivate' : 'Activate'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  SizedBox(width: 12),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditCategoryDialog(MarketplaceCategory category) {
    final nameController = TextEditingController(text: category.categoryName);
    final sortOrderController =
        TextEditingController(text: category.sortOrder.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Category Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: sortOrderController,
              decoration: const InputDecoration(
                labelText: 'Sort Order',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final sortOrder = int.tryParse(sortOrderController.text.trim());

              if (name.isEmpty || sortOrder == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter valid values'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              await _repository.updateCategory(category.id, {
                'categoryName': name,
                'sortOrder': sortOrder,
              });

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Category updated'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LISTINGS LIST (Active, Sold, Withdrawn)
  // ============================================================

  Widget _buildListingsList() {
    Stream<List<MarketplaceListing>> stream;

    switch (_activeView) {
      case 'active':
        stream = _repository.getListingsByStatus(ListingStatus.active);
        break;
      case 'sold':
        stream = _repository.getListingsByStatus(ListingStatus.sold);
        break;
      case 'withdrawn':
        stream = _repository.getListingsByStatus(ListingStatus.withdrawn);
        break;
      default:
        stream = _repository.getAllListingsForAdmin();
    }

    return StreamBuilder<List<MarketplaceListing>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
              ],
            ),
          );
        }

        final listings = snapshot.data ?? [];

        if (listings.isEmpty) {
          return _buildEmptyListings();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: listings.length,
          itemBuilder: (context, index) {
            return _buildListingCard(listings[index]);
          },
        );
      },
    );
  }

  Widget _buildEmptyListings() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.storefront, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No Listings',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _getEmptyMessage(),
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  String _getEmptyMessage() {
    switch (_activeView) {
      case 'active':
        return 'No active listings';
      case 'sold':
        return 'No sold items';
      case 'withdrawn':
        return 'No withdrawn listings';
      default:
        return 'No listings yet';
    }
  }

  Widget _buildListingCard(MarketplaceListing listing) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showListingDetails(listing),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photo
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: listing.photosRef.isNotEmpty
                    ? Image.network(
                        listing.photosRef.first,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 80,
                            height: 80,
                            color: Colors.grey[200],
                            child: const Icon(Icons.image, size: 32),
                          );
                        },
                      )
                    : Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey[200],
                        child: const Icon(Icons.image, size: 32),
                      ),
              ),
              const SizedBox(width: 12),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and Status
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            listing.title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildStatusBadge(listing.status),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Price
                    Text(
                      '₱${listing.price.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Seller
                    Row(
                      children: [
                        Icon(Icons.person, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            listing.sellerName,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Category and Date
                    Row(
                      children: [
                        Icon(Icons.label_outline,
                            size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          listing.categoryName ?? 'Uncategorized',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          listing.timeAgo,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(ListingStatus status) {
    Color color;
    String text;

    switch (status) {
      case ListingStatus.active:
        color = Colors.green;
        text = 'Active';
        break;
      case ListingStatus.sold:
        color = Colors.orange;
        text = 'Sold';
        break;
      case ListingStatus.withdrawn:
        color = Colors.grey;
        text = 'Withdrawn';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  void _showListingDetails(MarketplaceListing listing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(24),
          child: ListView(
            controller: controller,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Title and Status
              Row(
                children: [
                  Expanded(
                    child: Text(
                      listing.title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildStatusBadge(listing.status),
                ],
              ),
              const SizedBox(height: 8),

              // Price
              Text(
                listing.priceText,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2563EB),
                ),
              ),
              const SizedBox(height: 16),

              // Seller Info
              _buildInfoRow(Icons.person, 'Seller', listing.sellerName),
              if (listing.sellerPhone != null) ...[
                const SizedBox(height: 8),
                _buildInfoRow(Icons.phone, 'Phone', listing.sellerPhone!),
              ],
              if (listing.sellerLotNumber != null) ...[
                const SizedBox(height: 8),
                _buildInfoRow(Icons.home, 'Lot', listing.sellerLotNumber!),
              ],
              const SizedBox(height: 8),
              _buildInfoRow(
                  Icons.label, 'Category', listing.categoryName ?? 'N/A'),
              const SizedBox(height: 8),
              _buildInfoRow(Icons.verified, 'Condition', listing.conditionText),
              const SizedBox(height: 8),
              _buildInfoRow(Icons.access_time, 'Posted', listing.timeAgo),
              const SizedBox(height: 20),

              // Description
              const Text(
                'Description',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                listing.description,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[700],
                  height: 1.5,
                ),
              ),

              // Photos
              if (listing.photosRef.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Text(
                  'Photos',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 200,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: listing.photosRef.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            listing.photosRef[index],
                            width: 200,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 200,
                                color: Colors.grey[200],
                                child:
                                    const Icon(Icons.error_outline, size: 48),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],

              // Delete Button
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.pop(context);
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete Listing'),
                        content: Text(
                          'Are you sure you want to delete "${listing.title}"? This action cannot be undone.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );

                    if (confirmed == true) {
                      try {
                        await _repository.deleteListing(listing.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Listing deleted successfully'),
                              backgroundColor: Colors.green,
                            ),
                          );
                          _loadCounts(); // Refresh counts
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to delete: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    }
                  },
                  icon: const Icon(Icons.delete),
                  label: const Text('Delete Listing'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
