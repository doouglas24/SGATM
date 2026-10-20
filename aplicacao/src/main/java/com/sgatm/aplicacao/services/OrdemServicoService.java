package com.sgatm_db.aplicacao.services;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import com.sgatm_db.aplicacao.repository.OrdemServicoRepository;

@Service
public class OrdemServicoService {

    @Autowired
    private OrdemServicoRepository ordemServicoRepository;

    @Transactional
    public void salvarOuAtualizar(Object ordemServico) {
        // Lógica transacional da Ordem de Serviço
    }
}