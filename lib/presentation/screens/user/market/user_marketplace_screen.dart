import 'package:flutter/material.dart';
import '../../../../data/models/marketplace_listing.dart';
import '../../../../data/repositories/marketplace_repository.dart';
import 'user_marketplace_my_listings_screen.dart';
import 'user_marketplace_listing_detail_screen.dart';

class UserMarketplaceScreen extends StatelessWidget {
  const UserMarketplaceScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final repository = MarketplaceRepository();

    return Stack(
      children: [
        // Main content
        StreamBuilder<List<MarketplaceListing>>(
          stream: repository.getAllActiveListings(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Error: ${snapshot.error}'),
                  ],
                ),
              );
            }

            final listings = snapshot.data ?? [];

            if (listings.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.storefront, size: 80, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'No Items for Sale',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Check back later for new listings',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              );
            }

            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.7,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: listings.length,
              itemBuilder: (context, index) {
                return _buildListingCard(context, listings[index]);
              },
            );
          },
        ),

        // Floating Action Button - My Listings
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.extended(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const UserMarketplaceMyListingsScreen(),
                ),
              );
            },
            backgroundColor: const Color(0xFF2563EB),
            icon: const Icon(Icons.list_alt),
            label: const Text('My Listings'),
          ),
        ),
      ],
    );
  }

  Widget _buildListingCard(BuildContext context, MarketplaceListing listing) {
    // Get first name only
    final firstName = listing.sellerName.split(' ').first;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UserMarketplaceListingDetailScreen(
                listing: listing,
              ),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image - Full width
            Expanded(
              child: Container(
                width: double.infinity,
                color: Colors.grey[200],
                child: listing.photosRef.isNotEmpty
                    ? Image.network(
                        listing.photosRef.first,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildPlaceholderImage();
                        },
                      )
                    : _buildPlaceholderImage(),
              ),
            ),

            // Info Section
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Price
                  Text(
                    '₱${listing.price.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Condition
                  Text(
                    listing.conditionText,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Time posted
                  Text(
                    'Posted ${listing.timeAgo}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 2),

                  // Seller first name
                  Text(
                    'by $firstName',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Center(
      child: Icon(
        Icons.shopping_bag_outlined,
        size: 64,
        color: Colors.grey[400],
      ),
    );
  }
}
