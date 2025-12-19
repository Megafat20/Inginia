<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class RegisterRequest extends FormRequest
{
    /**
     * Determine if the user is authorized to make this request.
     */
    public function authorize(): bool
    {
        return true;
    }

    /**
     * Get the validation rules that apply to the request.
     */
    public function rules(): array
    {
        return [
            'name' => 'nullable|string|max:255',
            'email' => 'required|string|email|unique:users,email',
            'password' => 'required|string|min:6',
            'phone' => 'nullable|string',
            'role' => 'nullable|string|in:client,prestataire,service',
            'service' => 'nullable|string',
            'location' => 'nullable|string',
            'adresse' => 'nullable|string',
            'profile_photo' => 'nullable|image|mimes:jpg,jpeg,png,gif|max:5120',
            'min_price' => 'nullable|numeric',
            'slogan' => 'nullable|string|max:255',
            'latitude' => 'nullable|numeric',
            'longitude' => 'nullable|numeric',
            'profession_ids' => 'nullable|array',
            'profession_ids.*' => 'exists:professions,id',
        ];
    }

    /**
     * Get custom messages for validator errors.
     */
    public function messages(): array
    {
        return [
            'email.required' => 'L\'adresse email est obligatoire.',
            'email.email' => 'L\'adresse email doit être valide.',
            'email.unique' => 'Cette adresse email est déjà utilisée.',
            'password.required' => 'Le mot de passe est obligatoire.',
            'password.min' => 'Le mot de passe doit contenir au moins 6 caractères.',
            'role.in' => 'Le rôle sélectionné n\'est pas valide.',
            'profile_photo.max' => 'La photo ne doit pas dépasser 5 Mo.',
            'profession_ids.*.exists' => 'Une profession sélectionnée n\'existe pas.',
        ];
    }
}
