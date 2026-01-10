import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Controllers
  final _nameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _serviceNameController =
      TextEditingController(); // Start-up agency name
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _minPriceController = TextEditingController();
  final _sloganController = TextEditingController();

  // State
  String _userType = 'client'; // 'client' or 'prestataire'
  bool _isAgency = false;
  final List<String> _selectedProfessions = [];

  final _formKey = GlobalKey<FormState>();

  // Mock professions data (You would fetch this from API normally)
  final List<Map<String, dynamic>> _mockProfessions = [
    {'id': '1', 'name': 'Plombier'},
    {'id': '2', 'name': 'Électricien'},
    {'id': '3', 'name': 'Menuisier'},
    {'id': '4', 'name': 'Peintre'},
    {'id': '5', 'name': 'Jardinier'},
    {'id': '6', 'name': 'Mécanicien'},
    {'id': '7', 'name': 'Informaticien'},
    {'id': '8', 'name': 'Coiffeur'},
  ];

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      body: Container(
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFEFF6FF), // blue-50
              Color(0xFFE0E7FF), // indigo-100
            ],
          ),
        ),
        child: SizedBox(
          height: MediaQuery.of(context).size.height,
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Header (Back button + Title)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: IconButton(
                        icon: const Icon(
                          Icons.arrow_back,
                          color: AppTheme.textDark,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),

                  // CARD BLANCHE
                  Container(
                    constraints: const BoxConstraints(maxWidth: 500),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Créer un compte',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Rejoignez notre plateforme 🚀',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Toggle Client / Prestataire
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: Row(
                            children: [
                              _buildToggleOption('Client', 'client'),
                              _buildToggleOption('Prestataire', 'prestataire'),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Message d'erreur
                        if (authProvider.error != null)
                          Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 24),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Text(
                              authProvider.error!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                        // Formulaire
                        Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_userType == 'client') ...[
                                _buildClientFields(),
                              ] else ...[
                                _buildProviderFields(),
                              ],

                              const SizedBox(height: 16),

                              // CHAMPS COMMUNS
                              Text('Email', style: _labelStyle),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _emailController,
                                decoration: _inputDecoration(
                                  'exemple@email.com',
                                  Icons.email_outlined,
                                ),
                                keyboardType: TextInputType.emailAddress,
                                validator: (val) =>
                                    val!.isEmpty ? 'Requis' : null,
                              ),
                              const SizedBox(height: 16),

                              Text('Mot de passe', style: _labelStyle),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: true,
                                decoration: _inputDecoration(
                                  '••••••••',
                                  Icons.lock_outline,
                                ),
                                validator: (val) => val!.length < 6
                                    ? '6 caractères minimum'
                                    : null,
                              ),
                              const SizedBox(height: 16),

                              Text('Téléphone', style: _labelStyle),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _phoneController,
                                decoration: _inputDecoration(
                                  '06 12 34 56 78',
                                  Icons.phone_outlined,
                                ),
                                keyboardType: TextInputType.phone,
                              ),

                              // Adresse pour tout le monde (dans React c'est dans "commun" ou Provider ?)
                              // Dans react: Client a pas "nom service", Provider a "adresse". Client a rien de spé?
                              // React: Client -> Nom/Prenom, Email, Pwd. Provider -> Nom/Prenom OR Service, Professions, MinPrice, Slogan, Email, Pwd, Phone, Address.
                              // On met Address en commun ou juste pour provider ?
                              // React: Address field appears in "Commun" section BUT inside provider block logic or generally visible.
                              // Looking closely at React code:
                              // Client Block: Nom, Prenom.
                              // Provider Block: IsAgency toggle, Nom/Prenom OR Service, Professions, MinPrice, Slogan.
                              // Commun Block: Email, Pwd. Then Phone. Then Photo. Then Address (Location/Adresse).
                              // So Address is for everyone potentially or at least Provider?
                              // React structure puts Address AFTER common block, but inside the main form.
                              // Let's add Address for everyone as it is useful.
                              const SizedBox(height: 16),
                              Text('Adresse principale', style: _labelStyle),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _addressController,
                                decoration: _inputDecoration(
                                  'Abidjan, Cocody...',
                                  Icons.location_on_outlined,
                                ),
                                validator: (val) =>
                                    val!.isEmpty ? 'Requis' : null,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Bouton Inscription
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: authProvider.isLoading
                                ? null
                                : () async {
                                    if (_formKey.currentState!.validate()) {
                                      _handleRegister(authProvider);
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 5,
                              shadowColor: AppTheme.primary.withOpacity(0.4),
                            ),
                            child: authProvider.isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : const Text("S'inscrire"),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Login Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Déjà un compte ? ",
                        style: GoogleFonts.inter(color: Colors.grey[600]),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Text(
                          "Se connecter",
                          style: GoogleFonts.inter(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- WIDGETS ---

  Widget _buildToggleOption(String label, String value) {
    final isSelected = _userType == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _userType = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(50),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : Colors.grey[600],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildClientFields() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Nom', style: _labelStyle),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameController,
                    decoration: _inputDecoration('Nom', Icons.person_outline),
                    validator: (val) => val!.isEmpty ? 'Requis' : null,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Prénom', style: _labelStyle),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _firstNameController,
                    decoration: _inputDecoration(
                      'Prénom',
                      Icons.person_outline,
                    ),
                    validator: (val) => val!.isEmpty ? 'Requis' : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProviderFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Checkbox Agency
        Theme(
          data: ThemeData(
            checkboxTheme: CheckboxThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          child: CheckboxListTile(
            title: Text(
              "Je suis une agence",
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            value: _isAgency,
            onChanged: (val) => setState(() => _isAgency = val ?? false),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: AppTheme.primary,
          ),
        ),
        const SizedBox(height: 8),

        if (!_isAgency) ...[
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Nom', style: _labelStyle),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameController,
                      decoration: _inputDecoration('Nom', Icons.person_outline),
                      validator: (val) => val!.isEmpty ? 'Requis' : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Prénom', style: _labelStyle),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _firstNameController,
                      decoration: _inputDecoration(
                        'Prénom',
                        Icons.person_outline,
                      ),
                      validator: (val) => val!.isEmpty ? 'Requis' : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ] else ...[
          Text('Nom du service', style: _labelStyle),
          const SizedBox(height: 8),
          TextFormField(
            controller: _serviceNameController,
            decoration: _inputDecoration('Nom de votre agence', Icons.business),
            validator: (val) => val!.isEmpty ? 'Requis' : null,
          ),
        ],
        const SizedBox(height: 16),

        // PROFESSIONS SELECTION
        Text('Sélectionnez vos professions', style: _labelStyle),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _mockProfessions.map((prof) {
            final isSelected = _selectedProfessions.contains(prof['id']);
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedProfessions.remove(prof['id']);
                  } else {
                    _selectedProfessions.add(prof['id']);
                  }
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primary : Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppTheme.primary : Colors.grey[300]!,
                  ),
                ),
                child: Text(
                  prof['name'],
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey[700],
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        if (_selectedProfessions.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              'Veuillez sélectionner au moins une profession',
              style: TextStyle(color: Colors.red[700], fontSize: 12),
            ),
          ),

        const SizedBox(height: 16),

        // PRIX & SLOGAN
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Prix min (XOF)', style: _labelStyle),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _minPriceController,
                    decoration: _inputDecoration('5000', Icons.attach_money),
                    keyboardType: TextInputType.number,
                    validator: (val) => val!.isEmpty ? 'Requis' : null,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        Text('Slogan / Description', style: _labelStyle),
        const SizedBox(height: 8),
        TextFormField(
          controller: _sloganController,
          decoration: _inputDecoration(
            'Expert en solutions...',
            Icons.short_text,
          ),
          validator: (val) => val!.isEmpty ? 'Requis' : null,
        ),
      ],
    );
  }

  // --- LOGIC ---

  Future<void> _handleRegister(AuthProvider authProvider) async {
    if (_userType == 'prestataire' && _selectedProfessions.isEmpty) {
      // Show validation error for missing professions
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Veuillez sélectionner au moins une profession"),
        ),
      );
      return;
    }

    // Construct Name
    String fullName;
    if (_userType == 'prestataire' && _isAgency) {
      fullName = _serviceNameController.text.trim();
    } else {
      fullName =
          "${_nameController.text.trim()} ${_firstNameController.text.trim()}";
    }

    // Call AuthProvider with all fields
    final success = await authProvider.register(
      name: fullName,
      email: _emailController.text,
      password: _passwordController.text,
      phone: _phoneController.text,
      role: _userType,
      isAgency: _userType == 'prestataire' ? _isAgency : null,
      professionIds: _userType == 'prestataire' ? _selectedProfessions : null,
      minPrice: _userType == 'prestataire' ? _minPriceController.text : null,
      slogan: _userType == 'prestataire' ? _sloganController.text : null,
      location: _addressController.text,
      adresse: _addressController
          .text, // Using same field for both location and adresse
      latitude: 0.0, // TODO: Get actual geolocation if needed
      longitude: 0.0,
    );

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Compte créé ! Connectez-vous.")),
      );
    }
  }

  TextStyle get _labelStyle => GoogleFonts.inter(
    fontWeight: FontWeight.w600,
    color: Colors.grey[700],
    fontSize: 14,
  );

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, size: 20),
      // Le reste est dans AppTheme
    );
  }
}
