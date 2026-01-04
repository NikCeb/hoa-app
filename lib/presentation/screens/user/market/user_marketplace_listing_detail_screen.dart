import 'package:flutter/material.dart';
import '../../../../data/models/marketplace_listing.dart';

class UserMarketplaceListingDetailScreen extends StatelessWidget {
  final MarketplaceListing listing;

  const UserMarketplaceListingDetailScreen({
    Key? key,
    required this.listing,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF2563EB),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Item Details',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        children: [
          // Photos Carousel
          if (listing.photosRef.isNotEmpty)
            SizedBox(
              height: 300,
              child: PageView.builder(
                itemCount: listing.photosRef.length,
                itemBuilder: (context, index) {
                  return Image.network(
                    listing.photosRef[index],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[200],
                        child: const Icon(
                          Icons.shopping_bag_outlined,
                          size: 100,
                          color: Colors.grey,
                        ),
                      );
                    },
                  );
                },
              ),
            )
          else
            Container(
              height: 300,
              color: Colors.grey[200],
              child: const Center(
                child: Icon(
                  Icons.shopping_bag_outlined,
                  size: 100,
                  color: Colors.grey,
                ),
              ),
            ),

          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  listing.title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Price
                Text(
                  '₱${listing.price.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2563EB),
                  ),
                ),
                if (listing.isNegotiable)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Negotiable',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                const SizedBox(height: 20),

                const Divider(),
                const SizedBox(height: 20),

                // Details Grid
                _buildDetailRow(
                    Icons.verified, 'Condition', listing.conditionText),
                const SizedBox(height: 12),
                _buildDetailRow(Icons.category, 'Category',
                    listing.categoryName ?? 'Uncategorized'),
                const SizedBox(height: 12),
                _buildDetailRow(Icons.access_time, 'Posted', listing.timeAgo),
                if (listing.location != null &&
                    listing.location!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildDetailRow(
                      Icons.location_on, 'Location', listing.location!),
                ],
                if (listing.allowsDelivery) ...[
                  const SizedBox(height: 12),
                  _buildDetailRow(
                      Icons.local_shipping, 'Delivery', 'Available'),
                ],
                const SizedBox(height: 20),

                const Divider(),
                const SizedBox(height: 20),

                // Description
                const Text(
                  'Description',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  listing.description,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey[800],
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 20),

                const Divider(),
                const SizedBox(height: 20),

                // Seller Info
                const Text(
                  'Seller Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _buildSellerInfo(),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildContactButton(context),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 15,
            color: Colors.grey[600],
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSellerInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFF2563EB),
                child: Text(
                  listing.sellerName[0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      listing.sellerName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (listing.sellerLotNumber != null)
                      Text(
                        'Lot ${listing.sellerLotNumber}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (listing.sellerPhone != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  listing.sellerPhone!,
                  style: const TextStyle(fontSize: 15),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContactButton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton.icon(
          onPressed: () {
            // TODO: Implement contact seller functionality
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Contact seller feature coming soon'),
              ),
            );
          },
          icon: const Icon(Icons.message),
          label: const Text('Contact Seller'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
        ),
      ),
    );
  }
}
