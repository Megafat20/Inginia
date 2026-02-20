<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class LoginRequest extends FormRequest
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
            'email' => 'required_without:phone|nullable|string|email',
            'phone' => 'required_without:email|nullable|string',
            'password' => 'required|string',
        ];
    }

    public function messages(): array
    {
        return [
            'email.required_without' => 'L\'email ou le téléphone est requis.',
            'email.email' => 'Format d\'email invalide.',
            'phone.required_without' => 'Le téléphone ou l\'email est requis.',
            'password.required' => 'Le mot de passe est requis.',
        ];
    }
}
