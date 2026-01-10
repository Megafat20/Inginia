import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/provider_list_provider.dart';
import '../theme/app_theme.dart';

class ProvidersListScreen extends StatefulWidget {
  const ProvidersListScreen({super.key});

  @override
  State<ProvidersListScreen> createState() => _ProvidersListScreenState();
}

class _ProvidersListScreenState extends State<ProvidersListScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch providers when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProviderListProvider>(
        context,
        listen: false,
      ).fetchProviders();
    });
  }

  @override
  Widget build(BuildContext context) {
    final providerList = Provider.of<ProviderListProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Nos Prestataires')),
      body: providerList.isLoading
          ? const Center(child: CircularProgressIndicator())
          : providerList.error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Erreur: ${providerList.error}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () => providerList.fetchProviders(),
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: providerList.providers.length,
              itemBuilder: (context, index) {
                final provider = providerList.providers[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // Avatar / Photo
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: AppTheme.primaryLight.withOpacity(
                            0.2,
                          ),
                          backgroundImage: provider.profilePhotoUrl != null
                              ? NetworkImage(provider.profilePhotoUrl!)
                              : null,
                          child: provider.profilePhotoUrl == null
                              ? Text(
                                  (provider.displayName.isNotEmpty
                                          ? provider.displayName[0]
                                          : '?')
                                      .toUpperCase(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 24,
                                    color: AppTheme.primary,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 16),
                        // Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                provider.displayName,
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              if (provider.location != null)
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on,
                                      size: 14,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      provider.location!,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium,
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                        // Action
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            // TODO: Navigate to Provider Details
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
