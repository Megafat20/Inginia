import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/admin_service.dart';
import '../../models/user_model.dart';

class UsersManagementScreen extends StatefulWidget {
  const UsersManagementScreen({super.key});

  @override
  State<UsersManagementScreen> createState() => _UsersManagementScreenState();
}

class _UsersManagementScreenState extends State<UsersManagementScreen> {
  final AdminService _adminService = AdminService();
  List<User> _users = [];
  List<User> _filteredUsers = [];
  bool _loading = true;
  String _filterRole = 'all';
  String _filterStatus = 'all'; // 'all', 'active', 'inactive'
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _searchController.addListener(_filterUsers);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _loading = true);
    try {
      final users = await _adminService.getAllUsers();
      if (mounted) {
        setState(() {
          _users = users;
          _filteredUsers = users;
          _loading = false;
        });
        _filterUsers();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _filterUsers() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      _filteredUsers = _users.where((user) {
        bool matchesRole = true;
        if (_filterRole == 'client') {
          matchesRole = user.role != 'prestataire' && user.role != 'admin';
        } else if (_filterRole == 'prestataire') {
          matchesRole = user.role == 'prestataire';
        }

        bool matchesStatus = true;
        if (_filterStatus == 'active') {
          matchesStatus = user.isActive;
        } else if (_filterStatus == 'inactive') {
          matchesStatus = !user.isActive;
        }

        bool matchesSearch =
            user.name.toLowerCase().contains(query) ||
            user.email.toLowerCase().contains(query) ||
            (user.phone?.contains(query) ?? false);

        return matchesRole && matchesStatus && matchesSearch;
      }).toList();
    });
  }

  Future<void> _toggleUserStatus(User user) async {
    try {
      final newStatus = await _adminService.toggleActiveStatus(user.id);
      setState(() {
        final index = _users.indexWhere((u) => u.id == user.id);
        if (index != -1) {
          _users[index] = _users[index].copyWith(isActive: newStatus);
          _filterUsers();
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus ? 'Utilisateur activé' : 'Utilisateur désactivé',
            ),
            backgroundColor: newStatus ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          'Utilisateurs',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: _loadUsers,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          // Elegant Header with Filters
          Container(
            padding: const EdgeInsets.only(bottom: 20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Rechercher par nom, email...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      _buildChip(
                        'Tout',
                        _filterRole == 'all',
                        (v) => setState(() => _filterRole = 'all'),
                      ),
                      const SizedBox(width: 8),
                      _buildChip(
                        'Clients',
                        _filterRole == 'client',
                        (v) => setState(() => _filterRole = 'client'),
                      ),
                      const SizedBox(width: 8),
                      _buildChip(
                        'Prestataires',
                        _filterRole == 'prestataire',
                        (v) => setState(() => _filterRole = 'prestataire'),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text('|', style: TextStyle(color: Colors.grey)),
                      ),
                      _buildChip(
                        'Actifs',
                        _filterStatus == 'active',
                        (v) => setState(() => _filterStatus = 'active'),
                      ),
                      const SizedBox(width: 8),
                      _buildChip(
                        'Inactifs',
                        _filterStatus == 'inactive',
                        (v) => setState(() => _filterStatus = 'inactive'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // List
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadUsers,
                    child: _filteredUsers.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.all(20),
                            itemCount: _filteredUsers.length,
                            itemBuilder: (context, index) =>
                                _buildUserTile(_filteredUsers[index]),
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, bool isSelected, Function(bool) onSelected) {
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: isSelected ? Colors.white : AppTheme.textSecondary,
        ),
      ),
      selected: isSelected,
      onSelected: (v) {
        onSelected(v);
        _filterUsers();
      },
      selectedColor: AppTheme.primary,
      backgroundColor: Colors.white,
      showCheckmark: false,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? AppTheme.primary : Colors.grey.shade200,
        ),
      ),
    );
  }

  Widget _buildUserTile(User user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: (user.isActive ? AppTheme.primary : Colors.grey)
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  image: user.profilePhotoUrl != null
                      ? DecorationImage(
                          image: NetworkImage(user.profilePhotoUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: user.profilePhotoUrl == null
                    ? Icon(
                        user.role == 'prestataire'
                            ? Icons.business_center_rounded
                            : Icons.person_rounded,
                        color: user.isActive ? AppTheme.primary : Colors.grey,
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
                      user.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppTheme.textDark,
                        decoration: user.isActive
                            ? null
                            : TextDecoration.lineThrough,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      user.email,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                      maxLines: 1,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: (user.isActive ? Colors.green : Colors.grey)
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        user.isActive ? 'ACTIF' : 'DÉSACTIVÉ',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: user.isActive ? Colors.green : Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Quick Toggle
              Switch.adaptive(
                value: user.isActive,
                onChanged: (v) => _toggleUserStatus(user),
                activeColor: Colors.green,
              ),
              // More
              PopupMenuButton(
                icon: const Icon(Icons.more_vert_rounded, color: Colors.grey),
                itemBuilder: (ctx) => [
                  PopupMenuItem(
                    onTap: () => _confirmDeleteUser(user),
                    child: const Row(
                      children: [
                        Icon(Icons.delete_outline_rounded, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Supprimer', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline_rounded,
            size: 80,
            color: Colors.grey.shade200,
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun utilisateur trouvé',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteUser(User user) {
    Future.delayed(Duration.zero, () {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Supprimer ?'),
          content: Text('Voulez-vous vraiment supprimer ${user.name} ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _deleteUser(user.id);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Supprimer'),
            ),
          ],
        ),
      );
    });
  }

  Future<void> _deleteUser(int userId) async {
    try {
      await _adminService.deleteUser(userId);
      _loadUsers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Utilisateur supprimé'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
